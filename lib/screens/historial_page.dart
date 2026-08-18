import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/historial_orden_model.dart';
import '../models/veh_model.dart';
import '../models/usuario_model.dart';
import '../services/historial_service.dart';
import '../services/veh_service.dart';
import '../services/usuario_service.dart';
import '../theme/theme_provider.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage>
    with WidgetsBindingObserver {
  List<VehiculoModel> _vehiculos = [];
  List<UsuarioModel> _usuarios = [];
  List<HistorialOrdenModel> _historial = [];
  int _vehiculoSeleccionado = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _vehiculos.isNotEmpty) {
      // Recargar historial al volver a la app por si se completó una orden
      _cargarHistorial(_vehiculos[_vehiculoSeleccionado].id);
    }
  }

  Future<void> _cargarDatosIniciales() async {
    await Future.wait([_cargarVehiculos(), _usuarioInformacion()]);
  }

  Future<void> _cargarVehiculos() async {
    try {
      final vehiculosJson = await VehService().obtenerMisVehiculos();
      final vehiculosList = vehiculosJson
          .map((v) => VehiculoModel.fromJson(v))
          .toList();

      setState(() {
        _vehiculos = vehiculosList;
        if (_vehiculos.isNotEmpty) {
          _cargarHistorial(_vehiculos[0].id);
        } else {
          _cargando = false;
        }
      });
    } catch (e) {
      print("Error cargando vehículos: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _usuarioInformacion() async {
    try {
      final usuariosJson = await UsuarioService().usuarioInfo();
      if (mounted) {
        setState(() {
          _usuarios = usuariosJson
              .map((v) => UsuarioModel.fromJson(v))
              .toList();
        });
      }
    } catch (e) {
      print("Error cargando usuario: $e");
    }
  }

  Future<void> _cargarHistorial(int vehiculoId) async {
    setState(() => _cargando = true);
    try {
      final historialData = await HistorialService()
          .obtenerHistorialPorVehiculo(vehiculoId);
      if (mounted) {
        setState(() {
          _historial = historialData;
          _cargando = false;
        });
      }
    } catch (e) {
      print("Error al obtener historial: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Permitimos que la estructura cargue primero
    final bool hayVehiculos = _vehiculos.isNotEmpty;
    final vehiculo = hayVehiculos ? _vehiculos[_vehiculoSeleccionado] : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF404040),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Xtreme Performance",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
        ],
      ),
      drawer: _buildDrawer(context, vehiculo),
      body: RefreshIndicator(
        onRefresh: () => _cargarHistorial(vehiculo!.id),
        color: const Color(0xFFE53935),
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : vehiculo == null
            ? const Center(child: Text("No tienes vehículos registrados"))
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Selector de vehículo
                  _buildVehicleSelector(context, vehiculo),
                  const SizedBox(height: 24),

                  // Título de la sección
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Historial de Servicios",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contenido: Lista o estado vacío
                  _historial.isEmpty
                      ? _buildEmptyState()
                      : _buildHistorialList(),
                ],
              ),
      ),
    );
  }

  Widget _buildVehicleSelector(BuildContext context, VehiculoModel vehiculo) {
    return GestureDetector(
      onTap: () => _mostrarSelectorVehiculo(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF404040),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (vehiculo.fullImagenUrl.isNotEmpty)
                  ? Image.network(
                      vehiculo.fullImagenUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildCarPlaceholder(56),
                    )
                  : _buildCarPlaceholder(56),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${vehiculo.marca} ${vehiculo.modelo}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Placa: ${vehiculo.placa}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Color(0xFFE53935),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Sin Historial",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "No hay servicios anteriores registrados para este vehículo.",
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _historial
            .map((orden) => _buildHistorialCard(orden))
            .toList(),
      ),
    );
  }

  Widget _buildHistorialCard(HistorialOrdenModel orden) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Color(0xFF404040), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orden.fechaFin ?? 'Fecha no disponible',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orden.titulo,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "S/ ${orden.costoTotal.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorVehiculo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: _vehiculos.length,
            itemBuilder: (_, i) {
              final v = _vehiculos[i];
              final seleccionado = i == _vehiculoSeleccionado;
              return InkWell(
                onTap: () {
                  setState(() {
                    _vehiculoSeleccionado = i;
                    _cargando = true;
                  });
                  Navigator.pop(context);
                  _cargarHistorial(v.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: seleccionado ? Colors.red : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (v.fullImagenUrl.isNotEmpty)
                            ? Image.network(
                                v.fullImagenUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCarPlaceholder(50),
                              )
                            : _buildCarPlaceholder(50),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${v.marca} ${v.modelo}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Placa: ${v.placa}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      if (seleccionado)
                        const Icon(Icons.check_circle, color: Colors.red),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCarPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color.fromARGB(255, 54, 54, 54),
      child: const Icon(Icons.directions_car, color: Colors.white),
    );
  }

  Drawer _buildDrawer(BuildContext context, VehiculoModel? vehiculo) {
    return Drawer(
      child: Container(
        color: const Color(0xFF404040),
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFE53935),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xtreme Performance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _usuarios.isNotEmpty
                              ? _usuarios[0].nombre
                              : "Cliente",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Drawer Items
            _drawerItem(
              context,
              icon: Icons.directions_car,
              text: "Seguimiento del vehículo",
              route: "/seguimiento",
            ),
            _drawerItem(
              context,
              icon: Icons.attach_money,
              text: "Estado financiero",
              route: "/estadoFinanciero",
            ),
            _drawerItem(
              context,
              icon: Icons.history,
              text: "Historial del vehículo",
              route: "/historial",
              selected: true,
            ),
            _drawerItem(
              context,
              icon: Icons.notifications,
              text: "Notificaciones",
              route: "/notificaciones",
            ),
            _drawerItem(
              context,
              icon: Icons.settings,
              text: "Ajustes",
              route: "/ajustes",
            ),

            const Spacer(),

            // Selected Vehicle
            if (vehiculo != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF565656),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: vehiculo.fullImagenUrl.isNotEmpty
                            ? Image.network(
                                vehiculo.fullImagenUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCarPlaceholder(50),
                              )
                            : _buildCarPlaceholder(50),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${vehiculo.marca} ${vehiculo.modelo} ${vehiculo.anio}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Placa: ${vehiculo.placa}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String route,
    bool selected = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!selected) context.go(route);
      },
      child: Container(
        color: selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 14),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
