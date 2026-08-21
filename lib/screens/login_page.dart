// login_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/notifications_service.dart';
import '../theme/theme_provider.dart';
import '../utils/dio_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores de los TextField
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estado para la visibilidad de la contraseña
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo y título
                const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 80,
                  color: Color(0xFF404040),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Xtreme Performance",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF404040),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¡La aplicación perfecta para el',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 0.5),
                const Text(
                  'seguimiento de tus vehículos y servicios!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 24),

                // Card de login
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Correo Electrónico
                      const Text(
                        "Correo electrónico",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF404040),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usuarioController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "ejemplo@correo.com",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contraseña
                      const Text(
                        "Contraseña",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF404040),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Ingresa tu contraseña",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Texto informativo
                      const Text(
                        "Si no tienes acceso, contacta con el administrador de Xtreme Performance",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón de login
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final correo = _usuarioController.text.trim();
                            final password = _passwordController.text.trim();

                            if (correo.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Completa todos los campos"),
                                ),
                              );
                              return;
                            }

                            // Validación de formato de correo
                            if (!correo.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "El correo debe contener un '@'",
                                  ),
                                ),
                              );
                              return;
                            }

                            final resultado = await AuthService().login(
                              _usuarioController.text,
                              _passwordController.text,
                            );

                            if (resultado != null) {
                              // Configurar el token en Dio para las peticiones inmediatas
                              DioClient.dio.options.headers['Authorization'] =
                                  'Bearer ${resultado.token}';

                              // Registramos el token push AHORA que ya hay sesión
                              // autenticada (antes del login, la petición fallaba
                              // silenciosamente por falta de Authorization).
                              NotificationService().getToken();

                              // Solo Admin conserva el control de tema.
                              if (resultado.rolNombre != 'ADMIN') {
                                ThemeProvider.instance.setDarkMode(false);
                              }

                              if (!context.mounted) return;

                              switch (resultado.rolNombre) {
                                case 'MECANICO':
                                  context.go('/mecanico');
                                  break;
                                case 'ADMIN':
                                  context.go('/admin');
                                  break;
                                default:
                                  context.go('/seguimiento');
                              }
                            } else {
                              // Error de login
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Usuario o contraseña incorrectos",
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Iniciar sesión",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
