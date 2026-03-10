// estado financiero del cliente

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/veh_model.dart';
import '../models/usuario_model.dart';
import '../models/finanza_model.dart';
import '../services/veh_service.dart';
import '../services/usuario_service.dart';
import '../services/finanza_service.dart';

class EstFinancieroPage extends StatefulWidget {
  const EstFinancieroPage({super.key});

  @override
  State<EstFinancieroPage> createState() => _EstFinancieroPageState();
}

class _EstFinancieroPageState extends State<EstFinancieroPage> {
  List<VehiculoModel> _vehiculos = [];
  List<UsuarioModel> _usuarios = [];
  List<FinanzaModel> _finanzas = [];
  double _totalDeuda = 0.0;
  int _vehiculoSeleccionado = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
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
          _cargarFinanzas(_vehiculos[0].id);
        } else {
          _cargando = false;
        }
      });
    } catch (e) {
      print("Error cargando vehículos: $e");
      setState(() => _cargando = false);
    }
  }

  Future<void> _usuarioInformacion() async {
    try {
      final usuariosJson = await UsuarioService().usuarioInfo();
      setState(() {
        _usuarios = usuariosJson.map((v) => UsuarioModel.fromJson(v)).toList();
      });
    } catch (e) {
      print("Error cargando usuario: $e");
    }
  }

  Future<void> _cargarFinanzas(int vehiculoId) async {
    try {
      final resultado = await FinanzaService().obtenerFinanzasPorVehiculo(
        vehiculoId,
      );
      setState(() {
        _finanzas = resultado['finanzas'];
        _totalDeuda = resultado['total'];
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final vehiculo = _vehiculos.isNotEmpty
        ? _vehiculos[_vehiculoSeleccionado]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4A8F),
        elevation: 0,
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
            icon: const Icon(Icons.dark_mode_outlined, color: Colors.white),
            onPressed: () {}, // Visual only
          ),
        ],
      ),

      // menú desplegable
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1F3C88),
          child: Column(
            children: [
              // HEADER
              Container(
                color: const Color(0xFFE53935),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
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
                selected: true,
              ),
              _drawerItem(
                context,
                icon: Icons.history,
                text: "Historial del vehículo",
                route: "/historial",
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

              // VEHÍCULO
              if (vehiculo != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C5BEA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            vehiculo.imagen ??
                                "https://placehold.co/50x50.png?text=Auto",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.white24,
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${vehiculo.marca} ${vehiculo.modelo}",
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
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      body: vehiculo == null
          ? const Center(child: Text("No tienes vehículos registrados"))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // SELECTOR DE VEHÍCULO (Estilo moderno)
                GestureDetector(
                  onTap: () => _mostrarSelectorVehiculo(context),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E4A8F),
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
                          child: Image.network(
                            vehiculo.imagen ??
                                "https://placehold.co/55x55.png?text=Auto",
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.white24,
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.directions_car,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
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
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Estado Financiero",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Detalle de costos para la orden actual",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // TARJETA DE TOTAL
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2E4A8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total del Servicio Actual",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "S/ ${_totalDeuda.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Desglose de Costos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                if (_finanzas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text("No hay costos registrados para esta orden."),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _finanzas
                          .map(
                            (finanza) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: finanza.tipo == 'base'
                                          ? Colors.blue.shade50
                                          : Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      finanza.tipo == 'base'
                                          ? Icons.build_circle_outlined
                                          : Icons.add_circle_outline,
                                      color: finanza.tipo == 'base'
                                          ? Colors.blue.shade800
                                          : Colors.red.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          finanza.concepto,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          finanza.tipo.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: finanza.tipo == 'base'
                                                ? Colors.blue.shade800
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "S/ ${finanza.monto.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE53935),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  // SELECTOR DE VEHÍCULO (Misma lógica que SeguimientoPage)
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
                    _cargando = true; // Mostrar loading mientras cambia
                  });
                  Navigator.pop(context);
                  _cargarFinanzas(v.id); // Recargar finanzas
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
                        child: Image.network(
                          v.imagen ??
                              "https://placehold.co/50x50.png?text=Auto",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.directions_car),
                        ),
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
}

// drawer
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
      context.go(route);
    },
    child: Container(
      color: selected ? const Color(0xFF2C5BEA) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    ),
  );
}
