import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:xtreme_performance/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:xtreme_performance/screens/ajustes_page.dart';
import 'package:xtreme_performance/screens/diagnostico_page.dart';
import 'package:xtreme_performance/screens/estado_financiero.dart';
import 'package:xtreme_performance/screens/finalizacion_page.dart';
import 'package:xtreme_performance/screens/historial_page.dart';
import 'package:xtreme_performance/screens/login_page.dart';
import 'package:xtreme_performance/screens/splash_screen.dart';
import 'package:xtreme_performance/screens/notificaciones_page.dart';
import 'package:xtreme_performance/screens/pruebas_page.dart';
import 'package:xtreme_performance/screens/reparacion_page.dart';
import 'package:xtreme_performance/screens/seguimiento_page.dart';
import 'package:xtreme_performance/screens/mecanico_ordenes_page.dart';
import 'package:xtreme_performance/screens/mecanico_orden_detalle_page.dart';
import 'package:xtreme_performance/screens/admin_dashboard_page.dart';
import 'package:xtreme_performance/screens/solicitudes_reserva_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/dio_client.dart';
import 'services/notifications_service.dart';
import 'theme/theme_provider.dart';

/// Manejador de mensajes en segundo plano. Debe ser una función global.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔹 Inicializamos el token en los headers si existe
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");
  if (token != null) {
    DioClient.dio.options.headers['Authorization'] = 'Bearer $token';
  }

  await ThemeProvider.instance.loadSavedTheme();

  runApp(const MyApp());
}

// Configuracion
final GoRouter appRouter = GoRouter(
  redirect: (BuildContext context, GoRouterState state) {
    // Verificamos si tenemos el token en los headers de Dio
    final bool isAuthenticated = DioClient.dio.options.headers.containsKey(
      'Authorization',
    );
    final bool isLoggingIn = state.matchedLocation == '/login';
    final bool isSplash = state.matchedLocation == '/';

    // Si no está autenticado y no está en login/splash, forzar ir a login
    if (!isAuthenticated && !isLoggingIn && !isSplash) {
      return '/login';
    }
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'login',
          builder: (BuildContext context, GoRouterState state) {
            return const LoginPage();
          },
        ),

        GoRoute(
          path: 'seguimiento',
          builder: (BuildContext context, GoRouterState state) {
            final ordenId = state.extra as String?;
            return SeguimientoPage(ordenId: ordenId);
          },
        ),

        GoRoute(
          path: 'estadoFinanciero',
          builder: (BuildContext context, GoRouterState state) {
            return const EstFinancieroPage();
          },
        ),

        GoRoute(
          path: 'historial',
          builder: (BuildContext context, GoRouterState state) {
            return const HistorialPage();
          },
        ),

        GoRoute(
          path: 'notificaciones',
          builder: (BuildContext context, GoRouterState state) {
            return const NotificacionesPage();
          },
        ),

        GoRoute(
          path: 'ajustes',
          builder: (BuildContext context, GoRouterState state) {
            return const AjustesPage();
          },
        ),

        GoRoute(
          path: 'diagnostico',
          builder: (BuildContext context, GoRouterState state) {
            final ordenId = state.extra as String?;
            return DiagnosticoPage(ordenId: ordenId);
          },
        ),

        GoRoute(
          path: 'reparacion',
          builder: (BuildContext context, GoRouterState state) {
            final ordenId = state.extra as String?;
            return ReparacionPage(ordenId: ordenId);
          },
        ),

        GoRoute(
          path: 'pruebas',
          builder: (BuildContext context, GoRouterState state) {
            final ordenId = state.extra as String?;
            return PruebasPage(ordenId: ordenId);
          },
        ),

        GoRoute(
          path: 'final',
          builder: (BuildContext context, GoRouterState state) {
            final ordenId = state.extra as String?;
            return FinalPage(ordenId: ordenId);
          },
        ),

        // --- Rutas exclusivas del rol MECANICO ---
        GoRoute(
          path: 'mecanico',
          builder: (BuildContext context, GoRouterState state) {
            return const MecanicoOrdenesPage();
          },
        ),

        GoRoute(
          path: 'mecanico/orden',
          builder: (BuildContext context, GoRouterState state) {
            final orden = state.extra as Map<String, dynamic>?;
            return MecanicoOrdenDetallePage(orden: orden);
          },
        ),

        // --- Rutas exclusivas del rol ADMIN ---
        GoRoute(
          path: 'admin',
          builder: (BuildContext context, GoRouterState state) {
            return const AdminDashboardPage();
          },
        ),

        GoRoute(
          path: 'admin/solicitudes',
          builder: (BuildContext context, GoRouterState state) {
            return const SolicitudesReservaPage();
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Inicializar el servicio de notificaciones después de que el primer frame sea dibujado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp.router(
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F6F8),
            colorSchemeSeed: const Color(0xFFE53935),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorSchemeSeed: const Color(0xFFE53935),
          ),
        );
      },
    );
  }
}
