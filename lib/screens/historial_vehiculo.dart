// Historial del vehiculo

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Historial de vehículo'),
            
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