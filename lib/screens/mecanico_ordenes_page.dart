import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mecanico_service.dart';
import '../services/notifications_service.dart';
import '../theme/theme_provider.dart';
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
        backgroundColor: const Color(0xFF404040),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mis órdenes asignadas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeProvider.instance.themeMode,
              builder: (context, mode, __) => Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: Colors.white,
              ),
            ),
            onPressed: () => ThemeProvider.instance.toggle(),
          ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        title: Text(
          orden['titulo']?.toString() ?? 'Orden #${orden['id']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            vehiculo != null
                ? '${vehiculo['marca'] ?? ''} ${vehiculo['modelo'] ?? ''} · Placa ${vehiculo['placa'] ?? ''}'
                : 'Vehículo no disponible',
          ),
        ),
        trailing: Chip(
          label: Text(
            estado.replaceAll('_', ' '),
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: estado == 'finalizado'
              ? Colors.green
              : (estado == 'pausado' ? Colors.orange : Colors.blueGrey),
        ),
        onTap: () {
          context.push('/mecanico/orden', extra: orden);
        },
      ),
    );
  }
}
