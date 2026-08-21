import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/orden_service.dart';
import '../models/evidencia_model.dart';
import '../theme/app_colors.dart';
import '../widgets/evidencias_section.dart';

class FinalPage extends StatefulWidget {
  final String? ordenId;
  const FinalPage({super.key, this.ordenId});

  @override
  State<FinalPage> createState() => _FinalPageState();
}

class _FinalPageState extends State<FinalPage> {
  final OrdenService _ordenService = OrdenService();
  bool _isLoadingData = true;
  String _estadoEtapa = 'pendiente';
  String _fechaActualizacion = "--/--/----";
  String _descripcionFinal = "Cargando detalles de entrega...";
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
        final List<dynamic>? etapas = data['etapas'];
        final finalEtapa = etapas?.firstWhere(
          (e) => e['etapa'] == 'finalizacion',
          orElse: () => null,
        );

        _estadoEtapa = finalEtapa != null ? finalEtapa['estado'] : 'pendiente';
        _descripcionFinal =
            data['descripcion'] ?? 'Revisión final y entrega del vehículo.';

        _evidencias = ((finalEtapa?['evidencias'] as List<dynamic>?) ?? [])
            .map((e) => EvidenciaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final rawDate = finalEtapa != null
            ? finalEtapa['updated_at']
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
                    const SizedBox(height: 24),
                    _buildApprovalPanel(context),
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
      decoration: const BoxDecoration(gradient: AppColors.redGradient),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check_circle_outline,
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
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
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
                      "Finalización",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Actualizado: $_fechaActualizacion",
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
            "Estado de etapa",
            _getStatusLabel(_estadoEtapa),
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
                    color: _getStatusBgColor(_estadoEtapa),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _getStatusTextColor(_estadoEtapa),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Descripción del Servicio",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            _descripcionFinal,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final bool isCompleted =
        _estadoEtapa.toLowerCase() == 'completado' ||
        _estadoEtapa.toLowerCase() == 'finalizado';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.pending_actions,
            color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? "Vehículo Listo" : "Finalizando entrega",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.green.shade900
                        : Colors.blue.shade900,
                  ),
                ),
                Text(
                  isCompleted
                      ? "Tu vehículo ya está listo para ser recogido."
                      : "Estamos preparando la documentación y los detalles finales para la entrega.",
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

  Widget _buildApprovalPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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
