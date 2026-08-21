import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../models/notification_model.dart';
import '../main.dart'; // Importante para acceder a appRouter

/// Servicio encargado de la gestión de notificaciones push con Firebase.
class NotificationService extends ChangeNotifier {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Estado para la UI
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasError = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  /// Contador de solicitudes de reserva nuevas recibidas mientras la app está
  /// abierta (para el punto rojo de la campanita del panel ADMIN).
  int pendingSolicitudesCount = 0;

  void resetPendingSolicitudesCount() {
    pendingSolicitudesCount = 0;
    notifyListeners();
  }

  /// Canal de notificación para Android (Requerido para Heads-up notifications)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificaciones de Taller',
    description: 'Canal utilizado para actualizaciones de órdenes de trabajo.',
    importance: Importance.max,
  );

  /// Inicializa la configuración de Firebase y notificaciones locales.
  Future<void> initialize(BuildContext context) async {
    try {
      await requestPermissions();
      await _setupLocalNotifications(context);
      await initInfo(context);
      await getToken();
    } catch (e) {
      debugPrint("Error inicializando NotificationService: $e");
    }
  }

  /// Solicita permisos de notificación para iOS y Android 13+.
  Future<void> requestPermissions() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint("Error al solicitar permisos: $e");
    }
  }

  /// Obtiene el token de FCM y lo sincroniza con el servidor Laravel.
  Future<void> getToken() async {
    try {
      // Verificamos primero el estado actual de los permisos
      NotificationSettings settings = await _fcm.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          "FCM: El usuario ha bloqueado las notificaciones en el navegador.",
        );
        return;
      }

      // En la Web, getToken requiere el parámetro vapidKey
      String? token = await _fcm.getToken(
        vapidKey:
            'BMQ507lxX1AY9QgZprhfuPjzF10Dx-mMee5JbX3FtF9xF9sRpuFIQE6fncpwBNM1mJ3b4PoGFO6rTE_ALj2ks9M',
      );

      if (token != null) {
        debugPrint("FCM Token: $token");

        await DioClient.setTokenHeader();
        await DioClient.dio.post(
          '/usuarios/fcm-token',
          data: {'fcm_token': token},
        );
      }
    } catch (e) {
      // Manejo específico para cuando el permiso es bloqueado
      debugPrint(
        "FCM: No se pudo obtener el token (Posiblemente permisos bloqueados): $e",
      );
    }
  }

  /// Elimina el token del servidor al cerrar sesión.
  /// Esto garantiza que no lleguen notificaciones después de hacer logout.
  Future<void> deleteToken() async {
    try {
      await DioClient.setTokenHeader();
      await DioClient.dio.post(
        '/usuarios/fcm-token',
        data: {'fcm_token': null}, // Enviamos null para desvincular
      );
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint("Error al eliminar token de FCM: $e");
    }
  }

  /// Configura el plugin de notificaciones locales para el manejo en primer plano.
  Future<void> _setupLocalNotifications(BuildContext context) async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          _handleNavigation(context, data);
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  /// Configura los listeners para los diferentes estados de la aplicación.
  Future<void> initInfo(BuildContext context) async {
    // 1. App en primer plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;

      // Verificamos si el usuario tiene silenciadas las alertas localmente
      final prefs = await SharedPreferences.getInstance();
      final bool silenciado = prefs.getBool('silenciar_alertas') ?? false;

      if (message.data['tipo'] == 'solicitud_reserva') {
        pendingSolicitudesCount++;
        notifyListeners();
      }

      if (notification != null) {
        // Insertar en la lista local para actualización en tiempo real de la UI
        final nuevaNotificacion = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch, // ID temporal
          type: message.data['tipo'] ?? 'servicio',
          title: notification.title ?? '',
          mensaje: notification.body ?? '',
          timestamp: DateTime.now(),
          isRead: false,
        );
        _notifications.insert(0, nuevaNotificacion);
        notifyListeners();

        if (silenciado) return;

        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 2. App en segundo plano (Background) abierta vía notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(context, message.data);
    });

    // 3. App cerrada (Terminated) abierta vía notificación
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(context, initialMessage.data);
    }
  }

  /// Lógica de redirección basada en el payload de la notificación.
  void _handleNavigation(BuildContext context, Map<String, dynamic> data) {
    debugPrint("DEBUG: Payload recibido en notificación: $data");

    // Si la notificación trae datos, intentamos crear un modelo temporal
    final idStr =
        data['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final id = int.tryParse(idStr) ?? 0;

    if (!_notifications.any((n) => n.id == id)) {
      _notifications.insert(
        0,
        NotificationModel(
          id: id,
          type: data['tipo'] ?? 'servicio',
          title: data['titulo'] ?? 'Actualización de Servicio',
          mensaje: data['mensaje'] ?? 'Se ha recibido una nueva actualización.',
          timestamp: DateTime.now(),
          isRead: true, // Se marca como leída porque el usuario hizo clic
        ),
      );
      notifyListeners();
    }

    // Si la notificación tiene un orden_id, navegamos a la pantalla correspondiente
    // Revisamos múltiples llaves posibles que el backend podría estar enviando
    final ordenId = (data['orden_id'] ?? data['id_orden'] ?? data['id'])
        ?.toString();

    if (ordenId != null && ordenId != "0") {
      debugPrint("Navegando a Seguimiento de Orden: $ordenId");
      appRouter.push('/diagnostico', extra: ordenId);
    } else {
      debugPrint(
        "ADVERTENCIA: No se encontró un orden_id válido en el payload.",
      );
    }
  }

  /// Carga el historial de notificaciones desde la API
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      await DioClient.setTokenHeader();

      // Verificación de Debug para el Error 500
      final token = DioClient.dio.options.headers['Authorization'];
      debugPrint("Llamando a /notificaciones con Token: $token");

      final response = await DioClient.dio.get('/notificaciones');

      if (response.statusCode == 200 && response.data is List) {
        _notifications = (response.data as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        debugPrint(
          "Servidor retornó un estado inesperado: ${response.statusCode}",
        );
        _hasError = true;
      }
    } on DioException catch (e) {
      // Capturamos el error específico de Dio para ver qué dice el servidor
      debugPrint("ERROR BACKEND (500): ${e.response?.data}");
      debugPrint("PATH: ${e.requestOptions.path}");
      _hasError = true;
    } catch (e) {
      debugPrint("Error inesperado: $e");
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Configura el listener de Sockets (Pusher/Laravel Echo)
  void listenToRealTimeNotifications(int clienteId) {
    // Ejemplo conceptual usando Pusher
    // El canal debe ser cliente.{id} según tu backend
    final channelName = 'cliente.$clienteId';

    debugPrint("Escuchando canal de socket: $channelName");

    // Aquí implementarías la lógica de tu librería de Sockets (ej: pusher_channels_flutter)
    // Al recibir el evento 'nuevo-evento':
    /*
    final nueva = NotificationModel.fromJson(data);
    _notifications.insert(0, nueva);
    notifyListeners();
    _showTopBanner(nueva.title, nueva.mensaje);
    */
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      try {
        await DioClient.dio.put('/notificaciones/$id/leer');
      } catch (e) {
        debugPrint("Error al marcar como leída: $e");
      }
    }
  }
}
