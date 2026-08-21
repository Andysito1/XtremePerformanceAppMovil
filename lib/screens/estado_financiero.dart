// estado financiero del cliente

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/veh_model.dart';
import '../models/usuario_model.dart';
import '../models/finanza_model.dart';
import '../services/veh_service.dart';
import '../services/usuario_service.dart';
import '../services/finanza_service.dart';
import '../models/historial_orden_model.dart';
import '../services/historial_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';

class EstFinancieroPage extends StatefulWidget {
  const EstFinancieroPage({super.key});

  @override
  State<EstFinancieroPage> createState() => _EstFinancieroPageState();
}

class _EstFinancieroPageState extends State<EstFinancieroPage> {
  List<VehiculoModel> _vehiculos = [];
  List<UsuarioModel> _usuarios = [];
  List<FinanzaModel> _finanzas = [];
  List<HistorialOrdenModel> _ordenes = [];
  double _totalDeuda = 0.0;
  int? _ordenSeleccionadaId;
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
          _seleccionarVehiculo(0);
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

  Future<void> _seleccionarVehiculo(int index) async {
    final vehiculoId = _vehiculos[index].id;
    setState(() {
      _vehiculoSeleccionado = index;
      _cargando = true;
    });
    await _cargarFinanzas(vehiculoId);
  }

  Future<void> _cargarFinanzas(int vehiculoId, {int? ordenId}) async {
    if (mounted) setState(() => _cargando = true);
    try {
      final resultado = await FinanzaService().obtenerFinanzasPorVehiculo(
        vehiculoId,
        ordenId: ordenId,
      );
      if (mounted) {
        setState(() {
          _finanzas = List<FinanzaModel>.from(resultado['finanzas']);
          _ordenes = List<HistorialOrdenModel>.from(resultado['ordenes']);
          _ordenSeleccionadaId = resultado['orden_seleccionada'];
          _totalDeuda = (resultado['total'] as num).toDouble();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Permitimos que la estructura cargue primero
    final bool hayVehiculos = _vehiculos.isNotEmpty;
    final vehiculo = hayVehiculos ? _vehiculos[_vehiculoSeleccionado] : null;

    // Obtener el título de la orden seleccionada para mostrarlo en la tarjeta
    final String tituloOrdenActual =
        _ordenSeleccionadaId != null && _ordenes.isNotEmpty
        ? _ordenes
              .firstWhere(
                (o) => o.id == _ordenSeleccionadaId,
                orElse: () => _ordenes.first,
              )
              .titulo
        : "Servicio Actual";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        ),
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
      ),

      // menú desplegable
      drawer: AppDrawer(
        currentRoute: '/estadoFinanciero',
        usuarioNombre: _usuarios.isNotEmpty ? _usuarios[0].nombre : 'Cliente',
        vehiculo: vehiculo,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          if (vehiculo != null) {
            await _cargarFinanzas(vehiculo.id, ordenId: _ordenSeleccionadaId);
          } else {
            await _cargarVehiculos();
          }
        },
        color: const Color(0xFFE53935),
        child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : vehiculo == null
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
                      gradient: AppColors.darkGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dark.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: vehiculo.fullImagenUrl.isNotEmpty
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
                        "Consulta el detalle de tus servicios",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // MENÚ FLOTANTE SELECTIVO
                      if (_ordenes.isNotEmpty) _buildSelectorOrdenes(),
                      if (_ordenes.isEmpty && !_cargando)
                        const Text(
                          "No se encontraron órdenes para este vehículo",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
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
                    gradient: AppColors.darkGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 90,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total: $tituloOrdenActual",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (_finanzas.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Gráfico de Costos",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGraficoBarras(),
                  const SizedBox(height: 24),
                ],

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
      ),
    );
  }

  Widget _buildGraficoBarras() {
    final double maxMonto = _finanzas
        .map((f) => f.monto)
        .fold(0.0, (a, b) => a > b ? a : b);
    final double techo = maxMonto <= 0 ? 10 : maxMonto * 1.2;

    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
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
      child: BarChart(
        BarChartData(
          maxY: techo,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final finanza = _finanzas[group.x.toInt()];
                return BarTooltipItem(
                  '${finanza.concepto}\nS/ ${finanza.monto.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _finanzas.length) {
                    return const SizedBox.shrink();
                  }
                  final concepto = _finanzas[index].concepto;
                  final abreviado = concepto.length > 8
                      ? '${concepto.substring(0, 8)}…'
                      : concepto;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      abreviado,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(_finanzas.length, (index) {
            final finanza = _finanzas[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: finanza.monto,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                  color: finanza.tipo == 'base'
                      ? Colors.blue.shade400
                      : const Color(0xFFE53935),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSelectorOrdenes() {
    final HistorialOrdenModel? ordenActual = _ordenes.isEmpty
        ? null
        : _ordenes.firstWhere(
            (o) => o.id == _ordenSeleccionadaId,
            orElse: () => _ordenes.first,
          );

    if (ordenActual == null) return const SizedBox.shrink();

    return PopupMenuButton<int>(
      tooltip: "Cambiar orden de servicio",
      onSelected: (int id) {
        _cargarFinanzas(_vehiculos[_vehiculoSeleccionado].id, ordenId: id);
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => _ordenes.map((orden) {
        return PopupMenuItem<int>(
          value: orden.id,
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: orden.id == _ordenSeleccionadaId
                    ? Colors.red
                    : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  orden.titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: orden.id == _ordenSeleccionadaId
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                ordenActual.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.swap_vert, color: Color(0xFFE53935)),
          ],
        ),
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
                  Navigator.pop(context);
                  _seleccionarVehiculo(i);
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
      color: AppColors.darkElevated,
      child: const Icon(Icons.directions_car, color: Colors.white),
    );
  }
}
