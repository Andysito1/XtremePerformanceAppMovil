import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mecanico_service.dart';
import '../services/notifications_service.dart';
import '../theme/app_colors.dart';
import '../utils/dio_client.dart';

class MecanicoOrdenesPage extends StatefulWidget {
  const MecanicoOrdenesPage({super.key});

  @override
  State<MecanicoOrdenesPage> createState() => _MecanicoOrdenesPageState();
}

class _MecanicoOrdenesPageState extends State<MecanicoOrdenesPage> {
  final MecanicoService _mecanicoService = MecanicoService();
  List<dynamic> _ordenes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarOrdenes();
  }

  Future<void> _cargarOrdenes() async {
    if (mounted) setState(() => _cargando = true);
    final ordenes = await _mecanicoService.obtenerMisOrdenes();
    if (mounted) {
      setState(() {
        _ordenes = ordenes;
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    try {
      await NotificationService().deleteToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    } catch (_) {
    } finally {
      DioClient.dio.options.headers.remove('Authorization');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mis órdenes asignadas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarOrdenes,
        color: const Color(0xFFE53935),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _ordenes.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text('No tienes órdenes asignadas por ahora.'),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ordenes.length,
                itemBuilder: (context, index) {
                  final orden = _ordenes[index] as Map<String, dynamic>;
                  return _buildOrdenCard(context, orden);
                },
              ),
      ),
    );
  }

  Widget _buildOrdenCard(BuildContext context, Map<String, dynamic> orden) {
    final vehiculo = orden['vehiculo'] as Map<String, dynamic>?;
    final estado = (orden['estado'] ?? 'en_proceso').toString();
    final Color estadoColor = estado == 'finalizado'
        ? Colors.green
        : (estado == 'pausado' ? Colors.orange : Colors.blueGrey);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.push('/mecanico/orden', extra: orden);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.dark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: AppColors.dark,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orden['titulo']?.toString() ?? 'Orden #${orden['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vehiculo != null
                        ? '${vehiculo['marca'] ?? ''} ${vehiculo['modelo'] ?? ''} · Placa ${vehiculo['placa'] ?? ''}'
                        : 'Vehículo no disponible',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
      ),
    );
  }
}
