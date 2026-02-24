// seguimiento_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xtreme_performance/models/usuario_model.dart';
import '../services/veh_service.dart';
import '../models/veh_model.dart';
import '../services/usuario_service.dart';

class SeguimientoPage extends StatefulWidget {
  const SeguimientoPage({super.key});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  List<VehiculoModel> _vehiculos = [];
  List<UsuarioModel> _usuarios = [];
  int _vehiculoSeleccionado = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
    _usuarioInformacion();
  }

  Future<void> _cargarVehiculos() async {
    try {
      final vehiculosJson = await VehService().obtenerMisVehiculos();
      final vehiculosList = vehiculosJson
          .map((v) => VehiculoModel.fromJson(v))
          .toList();

      setState(() {
        _vehiculos = vehiculosList;
        _cargando = false;
      });
    } catch (e) {
      print("Error al cargar vehículos: $e");
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _usuarioInformacion() async {
    try {
      final usuariosJson = await UsuarioService().usuarioInfo();
      final usuariosList = usuariosJson
          .map((v) => UsuarioModel.fromJson(v))
          .toList();

      setState(() {
        _usuarios = usuariosList;
        _cargando = false;
      });
    } catch (e) {
      print("Error al cargar el usuario $e");
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehiculos.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("No tienes vehículos registrados"),
        ),
      );
    }

    final usuario = _usuarios;

    final vehiculo = _vehiculos[_vehiculoSeleccionado];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3C88),
        title: const Text(
          "Xtreme Performance",
          style: TextStyle(color: Colors.white),
        ),
      ),

      // drawer
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1F3C88),
          child: Column(
            children: [
              // header
              Container(
                color: const Color(0xFFE53935),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                            "Andy",
                            style: TextStyle(
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
                selected: true,
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

              // VEHÍCULO seleccionado en drawer
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
                              "https://via.placeholder.com/50x50.png?text=Auto",
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SELECTOR DE VEHÍCULO
          GestureDetector(
            onTap: () => _mostrarSelectorVehiculo(context),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      vehiculo.imagen ??
                          "https://via.placeholder.com/55x55.png?text=Auto",
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.white24,
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
                          ),
                        ),
                        Text(
                          "Placa: ${vehiculo.placa}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.red),
                ],
              ),
            ),
          ),

          const Text(
            "Seguimiento del Servicio",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Estado actual de tu vehículo",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),

          _etapaServicio(
            context,
            icon: Icons.assignment_turned_in,
            color: Colors.green,
            titulo: "Diagnóstico",
            descripcion: "Inspección inicial y diagnóstico del vehículo",
            estado: "Completado",
            fecha: "2 de Enero, 2026 - 09:30",
            ruta: "/diagnostico",
          ),

          _etapaServicio(
            context,
            icon: Icons.build,
            color: Colors.orange,
            titulo: "Reparación",
            descripcion: "Reparación de componentes identificados",
            estado: "En progreso",
            fecha: "3 de Enero, 2026 - 10:15",
            ruta: "/reparacion",
          ),

          _etapaServicio(
            context,
            icon: Icons.science,
            color: Colors.grey,
            titulo: "Pruebas",
            descripcion: "Pruebas de funcionamiento y calidad",
            estado: "Pendiente",
            fecha: "Por iniciar",
            ruta: "/pruebas",
          ),

          _etapaServicio(
            context,
            icon: Icons.check_circle,
            color: Colors.grey,
            titulo: "Finalización",
            descripcion: "Revisión final y entrega del vehículo",
            estado: "Pendiente",
            fecha: "Por iniciar",
            ruta: "/final",
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Nota: Puedes hacer clic en cada etapa para ver más detalles y aprobar el avance del servicio.",
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM SHEET SELECTOR DE VEHÍCULO
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
                  setState(() => _vehiculoSeleccionado = i);
                  Navigator.pop(context);
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
                          v.imagen ?? "https://via.placeholder.com/50x50.png?text=Auto",
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.directions_car),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${v.marca} ${v.modelo} ${v.anio}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
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

// drawer item
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

// etapa del servicio
Widget _etapaServicio(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String titulo,
  required String descripcion,
  required String estado,
  required String fecha,
  required String ruta,
}) {
  return InkWell(
    onTap: () => context.go(ruta),
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(descripcion, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(fecha, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            estado,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
