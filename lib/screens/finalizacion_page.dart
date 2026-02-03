import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinalPage extends StatefulWidget {
  const FinalPage({super.key});

  @override
  State<FinalPage> createState() => _FinalPageState();
}

class _FinalPageState extends State<FinalPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finalización"), centerTitle: true),
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
                    "Descripción",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text("Revisión final y entrega"),
                  Text("Estado: Pendiente"),
                  Text("Técnico asignado: Carlos Méndez"),
                  Text("Tiempo estimado: 2-3 horas"),
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
                    "Selecciona una opción para indicar tu decisión sobre esta etapa del servicio:",
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
