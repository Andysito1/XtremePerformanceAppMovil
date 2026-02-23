import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xtreme_performance/screens/ajustes_page.dart';
import 'package:xtreme_performance/screens/diagnostico_page.dart';
import 'package:xtreme_performance/screens/estado_financiero.dart';
import 'package:xtreme_performance/screens/finalizacion_page.dart';
import 'package:xtreme_performance/screens/historial_vehiculo.dart';
import 'package:xtreme_performance/screens/login_page.dart';
import 'package:xtreme_performance/screens/splash_screen.dart';
import 'package:xtreme_performance/screens/notificaciones_page.dart';
import 'package:xtreme_performance/screens/pruebas_page.dart';
import 'package:xtreme_performance/screens/reparacion_page.dart';
import 'package:xtreme_performance/screens/seguimiento_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Inicializamos el token en los headers si existe
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");
  if (token != null) {
    DioClient.dio.options.headers['Authorization'] = 'Bearer $token';
  }

  runApp(const MyApp());
}

// Configuracion
final GoRouter _router = GoRouter(
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
            return const SeguimientoPage();
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
            return const DiagnosticoPage();
          },
        ),

        GoRoute(
          path: 'reparacion',
          builder: (BuildContext context, GoRouterState state) {
            return const ReparacionPage();
          },
        ),

        GoRoute(
          path: 'pruebas',
          builder: (BuildContext context, GoRouterState state) {
            return const PruebasPage();
          },
        ),

        GoRoute(
          path: 'final',
          builder: (BuildContext context, GoRouterState state) {
            return const FinalPage();
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
