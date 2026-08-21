import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xtreme_performance/models/notification_model.dart';
import 'package:xtreme_performance/models/usuario_model.dart';
import 'package:xtreme_performance/models/veh_model.dart';
import 'package:xtreme_performance/services/notifications_service.dart';
import 'package:xtreme_performance/services/usuario_service.dart';
import 'package:xtreme_performance/services/veh_service.dart';
import 'package:xtreme_performance/theme/app_colors.dart';
import 'package:xtreme_performance/widgets/app_drawer.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage>
    with WidgetsBindingObserver {
  // Acceso al Singleton correcto
  final NotificationService _notificationService = NotificationService();
  final UsuarioService _usuarioService = UsuarioService();
  final VehService _vehService = VehService();

  UsuarioModel? _usuario;
  List<VehiculoModel> _vehiculos = [];
  int _vehiculoSeleccionado = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarUsuario();
    _cargarVehiculos();
    _notificationService.fetchNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Se actualiza solo al volver a la aplicación
      _notificationService.fetchNotifications();
    }
  }

  Future<void> _cargarVehiculos() async {
    try {
      final vehiculosJson = await _vehService.obtenerMisVehiculos();
      if (mounted) {
        setState(() {
          _vehiculos = vehiculosJson
              .map((v) => VehiculoModel.fromJson(v))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error al cargar vehículos: $e");
    }
  }

  Future<void> _cargarUsuario() async {
    try {
      final usuariosJson = await _usuarioService.usuarioInfo();
      if (usuariosJson.isNotEmpty && mounted) {
        setState(() => _usuario = UsuarioModel.fromJson(usuariosJson.first));
        // Cargamos las notificaciones del historial
      }
    } catch (e) {
      print("Error al cargar el usuario: $e");
    }
  }

  String _timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 0) {
      return 'Hace ${duration.inDays} día${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return 'Hace ${duration.inHours} hora${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return 'Hace ${duration.inMinutes} minuto${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Justo ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        ),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Xtreme Performance",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: AppDrawer(
        currentRoute: '/notificaciones',
        usuarioNombre: _usuario?.nombre ?? 'Cliente',
        vehiculo: _vehiculos.isNotEmpty
            ? _vehiculos[_vehiculoSeleccionado]
            : null,
      ),
      body:
          _notificationService.isLoading &&
              _notificationService.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _notificationService.fetchNotifications(),
              color: const Color(0xFFE53935),
              child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Actualizaciones de tus servicios',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildSectionTitle('HISTORIAL DE NOTIFICACIONES'),
                      ],
                    ),
                  ),
                ),
                // Corrección: Usamos ListenableBuilder en lugar de SliverAnimatedList
                ListenableBuilder(
                  listenable: _notificationService,
                  builder: (context, child) {
                    if (_notificationService.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const Text(
                                "No se pudieron cargar las notificaciones.",
                              ),
                              TextButton(
                                onPressed: () =>
                                    _notificationService.fetchNotifications(),
                                child: const Text("Reintentar"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_notificationService.notifications.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: Text("No tienes notificaciones.")),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildNotificationCard(
                          context,
                          _notificationService.notifications[index],
                        ),
                        childCount: _notificationService.notifications.length,
                      ),
                    );
                  },
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
  ) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          _notificationService.markAsRead(notification.id);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: !notification.isRead
                ? const Border(
                    left: BorderSide(color: AppColors.red, width: 3),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), // Sombra más sutil
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, // Un poco más grande para mejor visibilidad
                height: 48,
                decoration: BoxDecoration(
                  color: notification
                      .iconBackgroundColor, // Color pastel definido en el modelo
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // Bordes redondeados pero cuadrado
                ),
                child: Icon(
                  notification.iconData,
                  color: notification.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.mensaje,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(notification.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF757575),
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 1.0,
      ),
    );
  }

}
