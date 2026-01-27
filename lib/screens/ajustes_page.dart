// Ajustes

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [const Text('Ajustes'),
          
          ElevatedButton(
              onPressed: () {
                context.go("/seguimiento");
                },
                child: const Text("Seguimiento del vehículo"),
            ),

            ElevatedButton(
              onPressed: () {
                context.go("/estadoFinanciero");
                },
                child: const Text("Estado financiero"),
            ),

            ElevatedButton(
              onPressed: () {
                context.go("/historial");
                },
                child: const Text("Historial del vehículo"),
            ),

            ElevatedButton(
              onPressed: () {
                context.go("/ajustes");
                },
                child: const Text("Ajustes"),
            )
          ],
        ),
      ),
    );
  }
}