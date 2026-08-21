import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/evidencia_model.dart';
import '../services/evidencia_service.dart';
import '../theme/app_colors.dart';
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
      await _refrescarEvidenciasEtapa(etapaId);
      if (!mounted) return;
      setState(() => _subiendoEtapaId = null);

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

  Future<void> _refrescarEvidenciasEtapa(int etapaId) async {
    final nuevasEvidencias = await _evidenciaService.obtenerPorEtapa(etapaId);
    if (!mounted) return;
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
    });
  }

  Future<void> _eliminarEvidencia(int etapaId, EvidenciaModel evidencia) async {
    final exito = await _evidenciaService.eliminarEvidencia(evidencia.id);
    if (!mounted) return;

    if (exito) {
      await _refrescarEvidenciasEtapa(etapaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidencia eliminada'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la evidencia. Intenta de nuevo.'),
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
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _orden?['titulo']?.toString() ?? 'Detalle de orden',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _orden == null
          ? const Center(child: Text('No se pudo cargar la orden.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.darkGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehiculo != null
                                  ? '${vehiculo['marca'] ?? ''} ${vehiculo['modelo'] ?? ''}'
                                  : 'Vehículo no disponible',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (vehiculo != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Placa: ${vehiculo['placa'] ?? '-'}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                            if ((_orden?['descripcion']?.toString() ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _orden!['descripcion'].toString(),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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

    final Color estadoColor = estado == 'completado'
        ? Colors.green
        : (enProceso ? Colors.blue : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: estadoColor,
                  ),
                ),
              ),
            ],
          ),
          if (evidencias.isNotEmpty) ...[
            const SizedBox(height: 12),
            EvidenciasSection(
              evidencias: evidencias,
              onDelete: (evidencia) => _eliminarEvidencia(etapaId, evidencia),
            ),
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
