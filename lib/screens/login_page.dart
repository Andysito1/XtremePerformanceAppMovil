// Login

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: .center,
              children: [
                // Logo
                const SizedBox(height: 20),
                const Text(
                  "Xtreme Performance", // FALTABA COMA AQUÍ
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Seguimiento de Vehículo',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),

                // Card login
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      // Usuario / Correo
                      const Text(
                        "Usuario / Correo",
                        style: TextStyle(fontWeight: .w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "usuario@gmail.com",
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F2),
                          border: OutlineInputBorder(
                            borderRadius: .circular(10),
                            borderSide: .none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contraseña
                      const Text(
                        "Contraseña",
                        style: TextStyle(fontWeight: .w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "******",
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F2),
                          border: OutlineInputBorder(
                            borderRadius: .circular(10),
                            borderSide: .none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Texto informativo
                      const Text(
                        "Las credenciales son proporcionadas por \nXtreme Performance",
                        textAlign: .center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      // Boton
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: .circular(10),
                            ),
                          ),
                          onPressed: () {
                            context.go("/seguimiento");
                          },
                          child: const Text(
                            "Iniciar sesión",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Olvido contraseña
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(color: Colors.red),
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
