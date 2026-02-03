import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diagnóstico"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección Diagnóstico
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Diagnóstico",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Descripción: Inspección inicial y diagnóstico del vehículo",
                  ),
                  Text("Estado: Completado"),
                  Text("Técnico asignado: Carlos Méndez"),
                  Text("Tiempo estimado: 2-3 horas"),
                  Text("Fecha: 02/01/2026 - 09:30"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sección Aprobación del Cliente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Aprobación del Cliente",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Selecciona una opción para indicar tu decisión:",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  // Botones en orden
                  Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          context.go("/seguimiento");
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Aprobar avance"),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          // Acción solicitar aclaración
                        },
                        icon: const Icon(Icons.error_outline),
                        label: const Text("Solicitar aclaración"),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          // Acción rechazar/pausar
                        },
                        icon: const Icon(Icons.close),
                        label: const Text("Rechazar o pausar servicio"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Al aprobar, autorizas al taller a continuar con el siguiente paso del servicio.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
