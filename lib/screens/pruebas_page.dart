import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/orden_service.dart';
import '../models/evidencia_model.dart';
import '../widgets/evidencias_section.dart';

class PruebasPage extends StatefulWidget {
  final String? ordenId;
  const PruebasPage({super.key, this.ordenId});

  @override
  State<PruebasPage> createState() => _PruebasPageState();
}

class _PruebasPageState extends State<PruebasPage> {
  final OrdenService _ordenService = OrdenService();
  bool _isLoadingData = true;
  String _estadoEtapa = 'pendiente';
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
        final List<dynamic>? etapas = data['etapas'];
        final pruebasEtapa = etapas?.firstWhere(
          (e) => e['etapa'] == 'pruebas',
          orElse: () => null,
        );

        _estadoEtapa = pruebasEtapa != null
            ? pruebasEtapa['estado']
            : 'pendiente';

        _evidencias = ((pruebasEtapa?['evidencias'] as List<dynamic>?) ?? [])
            .map((e) => EvidenciaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final rawDate = pruebasEtapa != null
            ? pruebasEtapa['updated_at']
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.28,
      width: double.infinity,
      child: Image.network(
        "https://images.unsplash.com/photo-1517524008697-84bbe3c3fd98?q=80&w=2064&auto=format&fit=crop",
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Si la imagen falla (404), mostramos un fondo sólido con un icono
          return Container(
            color: const Color(0xFF404040),
            alignment: Alignment.center,
            child: const Icon(
              Icons.science_outlined,
              color: Colors.white,
              size: 50,
            ),
          );
        },
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
                  color: Color(0xFF404040),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_outlined,
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
                      "Pruebas",
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Control de Calidad",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
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
            isCompleted ? Icons.check_circle : Icons.biotech,
            color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? "Pruebas Superadas" : "En verificación",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.green.shade900
                        : Colors.blue.shade900,
                  ),
                ),
                Text(
                  isCompleted
                      ? "El vehículo está listo para ser entregado."
                      : "Estamos validando el correcto funcionamiento de los sistemas.",
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
