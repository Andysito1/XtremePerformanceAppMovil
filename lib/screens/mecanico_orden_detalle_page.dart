import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/evidencia_model.dart';
import '../services/evidencia_service.dart';
import '../widgets/evidencias_section.dart';

class MecanicoOrdenDetallePage extends StatefulWidget {
  final Map<String, dynamic>? orden;
  const MecanicoOrdenDetallePage({super.key, this.orden});

  @override
  State<MecanicoOrdenDetallePage> createState() =>
      _MecanicoOrdenDetallePageState();
}

class _MecanicoOrdenDetallePageState extends State<MecanicoOrdenDetallePage> {
  final EvidenciaService _evidenciaService = EvidenciaService();
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _orden;
  int? _subiendoEtapaId;

  static const Map<String, String> _nombresEtapa = {
    'diagnostico': 'Diagnóstico',
    'reparacion': 'Reparación',
    'pruebas': 'Pruebas de Calidad',
    'finalizacion': 'Finalización',
  };

  @override
  void initState() {
    super.initState();
    _orden = widget.orden;
  }

  List<dynamic> get _etapas =>
      (_orden?['etapas'] as List<dynamic>?) ?? const [];

  Future<void> _agregarEvidencia(Map<String, dynamic> etapa) async {
    final int etapaId = etapa['id'] is int
        ? etapa['id']
        : int.tryParse(etapa['id'].toString()) ?? 0;
    if (etapaId == 0) return;

    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (origen == null) return;

    final XFile? archivo = await _picker.pickImage(
      source: origen,
      imageQuality: 80,
    );
    if (archivo == null) return;

    setState(() => _subiendoEtapaId = etapaId);

    final exito = await _evidenciaService.subirEvidencia(
      etapaId,
      File(archivo.path),
    );

    if (!mounted) return;

    if (exito) {
      final nuevasEvidencias = await _evidenciaService.obtenerPorEtapa(
        etapaId,
      );
      setState(() {
        final etapasActualizadas = List<dynamic>.from(_etapas);
        final index = etapasActualizadas.indexWhere(
          (e) => (e['id'] ?? 0).toString() == etapaId.toString(),
        );
        if (index != -1) {
          etapasActualizadas[index] = {
            ...Map<String, dynamic>.from(etapasActualizadas[index]),
            'evidencias': nuevasEvidencias
                .map(
                  (e) => {
                    'id': e.id,
                    'tipo': e.tipo,
                    'url': e.url,
                    'descripcion': e.descripcion,
                  },
                )
                .toList(),
          };
          _orden = {..._orden!, 'etapas': etapasActualizadas};
        }
        _subiendoEtapaId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidencia agregada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _subiendoEtapaId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo subir la evidencia. Intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculo = _orden?['vehiculo'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF404040),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _orden?['titulo']?.toString() ?? 'Detalle de orden',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _orden == null
          ? const Center(child: Text('No se pudo cargar la orden.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehiculo != null
                              ? '${vehiculo['marca'] ?? ''} ${vehiculo['modelo'] ?? ''}'
                              : 'Vehículo no disponible',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (vehiculo != null)
                          Text('Placa: ${vehiculo['placa'] ?? '-'}'),
                        const SizedBox(height: 8),
                        Text(
                          _orden?['descripcion']?.toString() ?? '',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Etapas del servicio',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ..._etapas.map(
                  (etapa) => _buildEtapaCard(
                    Map<String, dynamic>.from(etapa as Map),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEtapaCard(Map<String, dynamic> etapa) {
    final String tipo = (etapa['etapa'] ?? '').toString();
    final String estado = (etapa['estado'] ?? 'pendiente').toString();
    final bool enProceso = estado == 'en_proceso';
    final int etapaId = etapa['id'] is int
        ? etapa['id']
        : int.tryParse(etapa['id'].toString()) ?? 0;
    final bool subiendo = _subiendoEtapaId == etapaId;

    final evidencias = ((etapa['evidencias'] as List<dynamic>?) ?? [])
        .map((e) => EvidenciaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _nombresEtapa[tipo] ?? tipo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Chip(
                label: Text(
                  estado.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: estado == 'completado'
                    ? Colors.green
                    : (enProceso ? Colors.blue : Colors.grey),
              ),
            ],
          ),
          if (evidencias.isNotEmpty) ...[
            const SizedBox(height: 12),
            EvidenciasSection(evidencias: evidencias),
          ],
          if (enProceso) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: subiendo ? null : () => _agregarEvidencia(etapa),
                icon: subiendo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  subiendo ? 'Subiendo...' : 'Agregar evidencia',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
