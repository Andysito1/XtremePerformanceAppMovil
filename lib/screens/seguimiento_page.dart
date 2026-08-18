// seguimiento_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xtreme_performance/models/usuario_model.dart';
import '../services/veh_service.dart';
import '../models/veh_model.dart';
import '../services/usuario_service.dart';
import '../services/seguimiento_service.dart';
import '../models/etapa_model.dart';
import '../theme/theme_provider.dart';

class SeguimientoPage extends StatefulWidget {
  final String? ordenId;
  const SeguimientoPage({super.key, this.ordenId});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage>
    with WidgetsBindingObserver {
  List<VehiculoModel> _vehiculos = [];
  List<UsuarioModel> _usuarios = [];
  List<EtapaModel> _etapas = [];
  String _tituloOrden = "Servicio Actual";
  int _vehiculoSeleccionado = 0;
  bool _cargando = true;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(
      this,
    ); // Añadir observador del ciclo de vida
    _cargarVehiculos();
    _usuarioInformacion();

    // Refresco silencioso automático cada 5 segundos, sin alertas ni
    // indicadores de carga, para reflejar avances del taller en tiempo real.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_vehiculos.isNotEmpty) {
        _cargarSeguimiento(_vehiculos[_vehiculoSeleccionado].id);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this); // Remover observador
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // La aplicación ha vuelto a estar activa (ej. se regresó de otra pantalla)
      // Recargar el seguimiento para asegurar que los datos estén actualizados
      if (_vehiculos.isNotEmpty) {
        _cargarSeguimiento(_vehiculos[_vehiculoSeleccionado].id);
      }
    }
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

        // Si hay vehículos, cargamos el seguimiento del primero
        if (_vehiculos.isNotEmpty) {
          _cargarSeguimiento(_vehiculos[0].id);
        }
      });
    } catch (e) {
      print("Error al cargar vehículos: $e");
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _cargarSeguimiento(int vehiculoId) async {
    // Opcional: poner loading local si se desea
    try {
      final resultado = await SeguimientoService()
          .obtenerSeguimientoPorVehiculo(vehiculoId);
      setState(() {
        _etapas = List<EtapaModel>.from(resultado['etapas']);
        _tituloOrden = resultado['titulo'];
      });
    } catch (e) {
      setState(() {
        _etapas = [];
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
    // Ya no bloqueamos todo el build.
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
            fontSize: 17,
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

      // drawer
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF404040),
          child: Column(
            children: [
              // header
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
              if (vehiculo != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 86, 86, 86),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (vehiculo.fullImagenUrl.isNotEmpty)
                              ? Image.network(
                                  vehiculo.fullImagenUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildCarPlaceholder(50),
                                )
                              : _buildCarPlaceholder(50),
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

      body: RefreshIndicator(
        onRefresh: () async {
          await _cargarVehiculos();
          if (_vehiculos.isNotEmpty) {
            await _cargarSeguimiento(_vehiculos[_vehiculoSeleccionado].id);
          }
        },
        color: const Color(0xFFE53935),
        child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _vehiculos.isEmpty
          ? ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 200),
                  child: Center(child: Text("No tienes vehículos registrados")),
                ),
              ],
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // 2. Tarjeta superior del vehículo (Selector estilizado)
                if (vehiculo != null)
                  GestureDetector(
                    onTap: () => _mostrarSelectorVehiculo(context),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
                            borderRadius: BorderRadius.circular(8),
                            child: (vehiculo.fullImagenUrl.isNotEmpty)
                                ? Image.network(
                                    vehiculo.fullImagenUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
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
                                  "${vehiculo.marca} ${vehiculo.modelo} ${vehiculo.anio}",
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
                          // Botón circular visual
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

                // 3. Header con imagen del vehículo
                if (vehiculo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Stack(
                      children: [
                        Container(
                          height: 220,
                          width: double.infinity,
                          child: vehiculo.fullImagenUrl.isNotEmpty
                              ? Image.network(
                                  vehiculo.fullImagenUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildCarPlaceholder(220, isHeader: true),
                                )
                              : _buildCarPlaceholder(220, isHeader: true),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildHeaderOverlay(vehiculo),
                        ),
                      ],
                    ),
                  ),

                // 6. Título de sección
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Seguimiento del Servicio",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tituloOrden,
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_etapas.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "No hay una orden de servicio activa para este vehículo.",
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _etapas.map((etapa) {
                        final color = _getColorForStatus(etapa.estado);
                        final icon = _getIconForType(etapa.tipo);
                        final ruta = _getRouteForType(etapa.tipo);

                        return _etapaServicio(
                          context,
                          id: etapa.id
                              .toString(), // Este ahora es id_orden gracias al modelo
                          icon: icon,
                          color: color,
                          titulo: etapa.titulo,
                          descripcion: etapa.descripcion,
                          estado: etapa.estado,
                          fecha: etapa.fecha ?? "Por iniciar",
                          ruta: ruta,
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 12),

                // 11. Caja de nota informativa
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0), // Rosado muy claro
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: const Text(
                    "Nota: Puedes hacer clic en cada etapa para ver más detalles.",
                    style: TextStyle(fontSize: 13, color: Color(0xFFD32F2F)),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildCarPlaceholder(double size, {bool isHeader = false}) {
    return Container(
      width: isHeader ? double.infinity : size,
      height: size,
      decoration: const BoxDecoration(color: Color.fromARGB(255, 54, 54, 54)),
      child: const Icon(Icons.directions_car, color: Colors.white, size: 30),
    );
  }

  Widget _buildHeaderOverlay(VehiculoModel vehiculo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0), Colors.black.withOpacity(0.6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${vehiculo.marca} ${vehiculo.modelo}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            vehiculo.placa,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers para mapear datos del backend a UI
  Color _getColorForStatus(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return const Color(0xFF4CAF50); // Verde
      case 'en progreso':
        return const Color(0xFFFBC02D); // Amarillo oscuro
      case 'pendiente':
      default:
        return Colors.grey; // Gris
    }
  }

  IconData _getIconForType(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'DIAGNOSTICO':
        return Icons.assignment_turned_in;
      case 'REPARACION':
        return Icons.build;
      case 'PRUEBAS':
        return Icons.science;
      case 'FINALIZACION':
        return Icons.check_circle;
      default:
        return Icons.settings;
    }
  }

  String _getRouteForType(String tipo) {
    // Mapea el tipo de etapa a la ruta de GoRouter
    switch (tipo.toUpperCase()) {
      case 'DIAGNOSTICO':
        return "/diagnostico";
      case 'REPARACION':
        return "/reparacion";
      case 'PRUEBAS':
        return "/pruebas";
      case 'FINALIZACION':
        return "/final";
      default:
        return "/seguimiento";
    }
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
                  setState(() {
                    _vehiculoSeleccionado = i;
                    _cargarSeguimiento(v.id);
                  });
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
                        child: (v.fullImagenUrl.isNotEmpty)
                            ? Image.network(
                                v.fullImagenUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
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
                              "${v.marca} ${v.modelo} ${v.anio}",
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
      color: selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
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
  required String id,
  required IconData icon,
  required Color color,
  required String titulo,
  required String descripcion,
  required String estado,
  required String fecha,
  required String ruta,
}) {
  // Lógica de bloqueo: Si está pendiente, no permite navegar
  final bool isLocked = estado.toLowerCase() == 'pendiente';
  final bool isCompleted = estado.toLowerCase() == 'completado';
  final bool isInProgress = estado.toLowerCase() == 'en progreso';

  // Configuración de colores para el badge
  Color badgeBgColor;
  Color badgeTextColor;

  if (isCompleted) {
    badgeBgColor = const Color(0xFFE8F5E9);
    badgeTextColor = const Color(0xFF2E7D32);
  } else if (isInProgress) {
    badgeBgColor = const Color(0xFFFFF9C4);
    badgeTextColor = const Color(0xFFF9A825);
  } else {
    badgeBgColor = const Color(0xFFF5F5F5);
    badgeTextColor = const Color(0xFF616161);
  }

  return InkWell(
    onTap: isLocked
        ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Esta etapa aún no ha iniciado."),
                backgroundColor: Colors.grey.shade800,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        : () {
            context.push(
              ruta,
              extra: id,
            ); // Usamos push para una transición más suave y rápida
          },
    child: Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 8. Icono circular y línea de tiempo
          _buildTimelineElement(isCompleted, isInProgress, icon),
          const SizedBox(width: 12),
          // 7. Tarjeta de progreso
          Expanded(
            child: _buildEtapaCard(
              titulo,
              estado,
              badgeBgColor,
              badgeTextColor,
              descripcion,
              fecha,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTimelineElement(
  bool isCompleted,
  bool isInProgress,
  IconData icon,
) {
  return SizedBox(
    width: 50,
    child: Column(
      children: [
        Container(width: 2, height: 20, color: Colors.grey.shade300),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFE8F5E9)
                : (isInProgress
                      ? const Color(0xFFFFF9C4)
                      : Colors.grey.shade100),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? Colors.green : Colors.transparent,
            ),
          ),
          child: Icon(
            icon,
            color: isCompleted
                ? Colors.green
                : (isInProgress ? Colors.orange[800] : Colors.grey),
            size: 20,
          ),
        ),
        Container(width: 2, height: 60, color: Colors.grey.shade300),
      ],
    ),
  );
}

Widget _buildEtapaCard(
  String titulo,
  String estado,
  Color badgeBgColor,
  Color badgeTextColor,
  String descripcion,
  String fecha,
) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          descripcion,
          style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              fecha,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    ),
  );
}
