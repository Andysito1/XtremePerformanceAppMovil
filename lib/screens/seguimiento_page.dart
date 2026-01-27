// Seguimiento del vehiculo

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SeguimientoPage extends StatefulWidget {
  const SeguimientoPage({super.key});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Xtreme Performance'),
            const Text('Seguimiento'),

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