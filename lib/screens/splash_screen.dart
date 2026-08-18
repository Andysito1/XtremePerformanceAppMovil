import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (mounted) context.go('/login');
        return;
      }

      final rol = prefs.getString('user_role');
      if (!mounted) return;

      switch (rol) {
        case 'MECANICO':
          context.go('/mecanico');
          break;
        default:
          context.go('/seguimiento');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car,
              size: 100,
              color: Color(0xFF404040), // Azul corporativo
            ),
            const SizedBox(height: 20),
            const Text(
              "Cargando...",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Color(0xFFE53935), // Rojo corporativo
            ),
          ],
        ),
      ),
    );
  }
}
