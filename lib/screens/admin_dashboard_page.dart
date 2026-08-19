import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_resumen_model.dart';
import '../services/dashboard_service.dart';
import '../services/notifications_service.dart';
import '../theme/theme_provider.dart';
import '../utils/dio_client.dart';

const List<String> _nombresMes = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const Map<String, String> _nombresEtapa = {
  'diagnostico': 'Diagnóstico',
  'reparacion': 'Reparación',
  'pruebas': 'Pruebas',
  'finalizacion': 'Finalización',
  'finalizado': 'Finalizado',
  'pausado': 'Pausado',
};

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  final TextEditingController _filtroClienteCtrl = TextEditingController();
  final TextEditingController _filtroPlacaCtrl = TextEditingController();

  final DateTime _hoy = DateTime.now();
  late int _anio = _hoy.year;
  late int _mes = _hoy.month;

  DashboardResumenModel? _resumen;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  @override
  void dispose() {
    _filtroClienteCtrl.dispose();
    _filtroPlacaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarResumen() async {
    if (mounted) setState(() => _cargando = true);
    final resumen = await _dashboardService.obtenerResumen(
      anio: _anio,
      mes: _mes,
    );
    if (mounted) {
      setState(() {
        _resumen = resumen;
        _cargando = false;
      });
    }
  }

  List<dynamic> get _ordenesFiltradas {
    final ordenes = _resumen?.ordenes ?? [];
    final cliente = _filtroClienteCtrl.text.trim().toLowerCase();
    final placa = _filtroPlacaCtrl.text.trim().toLowerCase();

    if (cliente.isEmpty && placa.isEmpty) return ordenes;

    return ordenes.where((o) {
      final vehiculo = o['vehiculo'] as Map<String, dynamic>?;
      final nombreCliente = (vehiculo?['cliente']?['usuario']?['nombre'] ?? '')
          .toString()
          .toLowerCase();
      final placaVehiculo = (vehiculo?['placa'] ?? '').toString().toLowerCase();

      final matchCliente = cliente.isEmpty || nombreCliente.contains(cliente);
      final matchPlaca = placa.isEmpty || placaVehiculo.contains(placa);
      return matchCliente && matchPlaca;
    }).toList();
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
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Dashboard',
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
        onRefresh: _cargarResumen,
        color: const Color(0xFFE53935),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSelectorMesAnio(),
                  const SizedBox(height: 16),
                  if (_resumen != null) _buildResumenCards(_resumen!),
                  const SizedBox(height: 20),
                  const Text(
                    'Filtrar órdenes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _filtroClienteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _filtroPlacaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Órdenes (${_ordenesFiltradas.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_ordenesFiltradas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No hay órdenes que coincidan con el filtro.'),
                      ),
                    )
                  else
                    ..._ordenesFiltradas.map(
                      (o) => _buildOrdenTile(Map<String, dynamic>.from(o)),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSelectorMesAnio() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _mes,
            decoration: const InputDecoration(
              labelText: 'Mes',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: List.generate(
              12,
              (i) => DropdownMenuItem(value: i + 1, child: Text(_nombresMes[i])),
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _mes = value);
              _cargarResumen();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: _anio,
            decoration: const InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: List.generate(6, (i) => _hoy.year - i)
                .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _anio = value);
              _cargarResumen();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResumenCards(DashboardResumenModel resumen) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _buildStatCard(
          'Órdenes del mes',
          '${resumen.totalOrdenesMes}',
          Icons.assignment_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          'Finalizadas',
          '${resumen.ordenesFinalizadasMes}',
          Icons.check_circle_outline,
          Colors.green,
        ),
        _buildStatCard(
          'Activas ahora',
          '${resumen.ordenesActivasActual}',
          Icons.build_circle_outlined,
          Colors.orange,
        ),
        _buildStatCard(
          'Ingresos del mes',
          'S/ ${resumen.ingresosMes.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String valor,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenTile(Map<String, dynamic> orden) {
    final vehiculo = orden['vehiculo'] as Map<String, dynamic>?;
    final cliente = vehiculo?['cliente']?['usuario']?['nombre'] ?? 'N/A';
    final etapa = (orden['etapa_actual'] ?? orden['estado'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(orden['titulo']?.toString() ?? 'Orden #${orden['id']}'),
        subtitle: Text(
          '$cliente · ${vehiculo?['marca'] ?? ''} ${vehiculo?['modelo'] ?? ''} (${vehiculo?['placa'] ?? '-'})',
        ),
        trailing: Chip(
          label: Text(
            _nombresEtapa[etapa] ?? etapa,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: etapa == 'finalizado' ? Colors.green : Colors.blueGrey,
        ),
      ),
    );
  }
}
