import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/solicitud_reserva_model.dart';
import '../services/solicitud_reserva_service.dart';

/// Vista de solo lectura para el rol ADMIN: muestra las solicitudes de
/// reserva pendientes enviadas desde la web pública. La decisión de
/// aprobar/rechazar se toma desde el panel web; aquí el admin solo
/// consulta los datos y contacta al cliente (copiar teléfono o WhatsApp).
class SolicitudesReservaPage extends StatefulWidget {
  const SolicitudesReservaPage({super.key});

  @override
  State<SolicitudesReservaPage> createState() =>
      _SolicitudesReservaPageState();
}

class _SolicitudesReservaPageState extends State<SolicitudesReservaPage> {
  final SolicitudReservaService _service = SolicitudReservaService();
  List<SolicitudReservaModel> _solicitudes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);
    final data = await _service.getPendientes();
    if (mounted) {
      setState(() {
        _solicitudes = data;
        _cargando = false;
      });
    }
  }

  Future<void> _copiarTelefono(String telefono) async {
    await Clipboard.setData(ClipboardData(text: telefono));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teléfono copiado al portapapeles')),
      );
    }
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    final numero = telefono.startsWith('+') ? telefono : '51$telefono';
    final uri = Uri.parse('https://wa.me/$numero');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF404040),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Solicitudes de Reserva',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              color: const Color(0xFFE53935),
              child: _solicitudes.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Text('No hay solicitudes pendientes.'),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _solicitudes.length,
                      itemBuilder: (context, index) =>
                          _buildCard(_solicitudes[index]),
                    ),
            ),
    );
  }

  Widget _buildCard(SolicitudReservaModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.tipoDocumentoAbreviatura} ${s.numeroDocumento}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Chip(
                label: const Text(
                  'Pendiente',
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: Colors.orange,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${s.vehiculoMarca} ${s.vehiculoModelo} (${s.vehiculoAnio})',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(s.correo, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          Text(s.problema),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copiarTelefono(s.telefono),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(s.telefono),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _abrirWhatsApp(s.telefono),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
