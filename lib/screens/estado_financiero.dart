// estado financiero del cliente

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EstFinancieroPage extends StatefulWidget {
  const EstFinancieroPage({super.key});

  @override
  State<EstFinancieroPage> createState() => _EstFinancieroPageState();
}

class _EstFinancieroPageState extends State<EstFinancieroPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Estado financiero'),
            
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