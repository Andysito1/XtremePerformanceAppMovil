// Login

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
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Página de Login'),
            ElevatedButton(
              onPressed: () {
                context.go("/seguimiento");
                },
                child: const Text("Iniciar sesión"),
              )
            ],
        ),
      ),
    );
  }
}