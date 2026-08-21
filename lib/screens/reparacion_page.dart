import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/orden_service.dart';
import '../models/evidencia_model.dart';
import '../theme/app_colors.dart';
import '../widgets/evidencias_section.dart';

class ReparacionPage extends StatefulWidget {
  final String? ordenId;
  const ReparacionPage({super.key, this.ordenId});

  @override
  State<ReparacionPage> createState() => _ReparacionPageState();
}

class _ReparacionPageState extends State<ReparacionPage> {
  final OrdenService _ordenService = OrdenService();
  bool _isLoadingData = true;
  String _estadoGeneral = 'en_proceso';
  String _descripcionReparacion = "Cargando detalles de la reparación...";
  String _fechaActualizacion = "--/--/----";
  List<EvidenciaModel> _evidencias = [];

  @override
  void initState() {
    super.initState();
    _cargarInformacionOrden();
  }

  Future<void> _cargarInformacionOrden() async {
    if (widget.ordenId == null || widget.ordenId == "0") {
      setState(() => _isLoadingData = false);
      return;
    }

    final data = await _ordenService.obtenerOrden(widget.ordenId!);
    if (data != null && mounted) {
      setState(() {
        // Buscar el estado específico de la etapa de reparación
        final List<dynamic>? etapas = data['etapas'];
        final reparacionEtapa = etapas?.firstWhere(
          (e) => e['etapa'] == 'reparacion',
          orElse: () => null,
        );

        _estadoGeneral = reparacionEtapa != null
            ? reparacionEtapa['estado']
            : 'pendiente'; // Si la etapa no se encuentra, se considera pendiente.

        _descripcionReparacion =
            data['descripcion'] ??
            'El vehículo se encuentra en el área de mecánica.';

        _evidencias = ((reparacionEtapa?['evidencias'] as List<dynamic>?) ?? [])
            .map((e) => EvidenciaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // Obtener la fecha de actualización específica de la etapa de reparación
        final rawDate = reparacionEtapa != null
            ? reparacionEtapa['updated_at']
            : data['updated_at'];

        if (rawDate != null) {
          try {
            final parsedDate = DateTime.parse(rawDate);
            _fechaActualizacion = DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(parsedDate);
          } catch (e) {
            _fechaActualizacion = rawDate.toString();
          }
        }
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        leadingWidth: 56,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildHeaderImage(context),
                ListView(
                  padding: const EdgeInsets.only(
                    top: 200,
                    left: 16,
                    right: 16,
                    bottom: 100,
                  ),
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildNotesBox(),
                    const SizedBox(height: 24),
                    EvidenciasSection(evidencias: _evidencias),
                    if (_evidencias.isNotEmpty) const SizedBox(height: 24),
                    _buildStatusTimeline(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.26,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.darkGradient),
      alignment: Alignment.center,
      child: const Icon(
        Icons.build_circle_outlined,
        color: Colors.white,
        size: 64,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.dark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Reparación",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Última actualización: $_fechaActualizacion",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            "Estado actual",
            _getStatusLabel(_estadoGeneral),
            isStatus: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(_estadoGeneral),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _getStatusTextColor(_estadoGeneral),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNotesBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Etapa de reparación dentro del servicio",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final bool isCompleted =
        _estadoGeneral.toLowerCase() == 'completado' ||
        _estadoGeneral.toLowerCase() == 'finalizado';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.sync,
            color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted
                      ? "Reparación Finalizada"
                      : "Trabajando en tu vehículo",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.green.shade900
                        : Colors.blue.shade900,
                  ),
                ),
                Text(
                  isCompleted
                      ? "Estamos preparando las pruebas finales."
                      : "El técnico está realizando las correcciones necesarias.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String estado) =>
      estado.replaceAll('_', ' ').toUpperCase();
  Color _getStatusBgColor(String estado) => estado.toLowerCase() == 'completado'
      ? Colors.green.shade100
      : Colors.blue.shade100;
  Color _getStatusTextColor(String estado) =>
      estado.toLowerCase() == 'completado'
      ? Colors.green.shade900
      : Colors.blue.shade900;
}
