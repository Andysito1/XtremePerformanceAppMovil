import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_resumen_model.dart';
import '../services/dashboard_service.dart';
import '../services/notifications_service.dart';
import '../services/solicitud_reserva_service.dart';
import '../theme/app_colors.dart';
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
  final SolicitudReservaService _solicitudReservaService = SolicitudReservaService();
  final TextEditingController _filtroClienteCtrl = TextEditingController();
  final TextEditingController _filtroPlacaCtrl = TextEditingController();

  final DateTime _hoy = DateTime.now();
  late int _anio = _hoy.year;
  late int _mes = _hoy.month;

  DashboardResumenModel? _resumen;
  bool _cargando = true;
  int _solicitudesPendientesBase = 0;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
    _cargarSolicitudesPendientes();
  }

  Future<void> _cargarSolicitudesPendientes() async {
    final count = await _solicitudReservaService.getPendientesCount();
    if (mounted) setState(() => _solicitudesPendientesBase = count);
  }

  Future<void> _abrirSolicitudes() async {
    await context.push('/admin/solicitudes');
    NotificationService().resetPendingSolicitudesCount();
    _cargarSolicitudesPendientes();
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
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          ListenableBuilder(
            listenable: NotificationService(),
            builder: (context, __) {
              final total = _solicitudesPendientesBase +
                  NotificationService().pendingSolicitudesCount;
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white),
                    if (total > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: _abrirSolicitudes,
              );
            },
          ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.filter_alt_outlined,
                                color: AppColors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Filtrar órdenes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                      ],
                    ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
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
    final bool finalizado = etapa == 'finalizado';
    final Color etapaColor = finalizado ? Colors.green : Colors.blueGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.dark.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.dark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orden['titulo']?.toString() ?? 'Orden #${orden['id']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$cliente · ${vehiculo?['marca'] ?? ''} ${vehiculo?['modelo'] ?? ''} (${vehiculo?['placa'] ?? '-'})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: etapaColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: etapaColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _nombresEtapa[etapa] ?? etapa,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: etapaColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
