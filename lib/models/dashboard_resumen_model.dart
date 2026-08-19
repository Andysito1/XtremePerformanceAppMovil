class DashboardResumenModel {
  final int anio;
  final int mes;
  final int totalOrdenesMes;
  final int ordenesFinalizadasMes;
  final int ordenesActivasActual;
  final double ingresosMes;
  final double ingresoPromedioOrden;
  final Map<String, int> porEstado;
  final Map<String, int> porMecanico;
  final Map<String, int> porServicio;
  final List<dynamic> ordenes;

  DashboardResumenModel({
    required this.anio,
    required this.mes,
    required this.totalOrdenesMes,
    required this.ordenesFinalizadasMes,
    required this.ordenesActivasActual,
    required this.ingresosMes,
    required this.ingresoPromedioOrden,
    required this.porEstado,
    required this.porMecanico,
    required this.porServicio,
    required this.ordenes,
  });

  static Map<String, int> _parseCounts(dynamic raw) {
    if (raw is Map) {
      return raw.map(
        (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
      );
    }
    return {};
  }

  factory DashboardResumenModel.fromJson(Map<String, dynamic> json) {
    return DashboardResumenModel(
      anio: json['anio'] ?? 0,
      mes: json['mes'] ?? 0,
      totalOrdenesMes: json['total_ordenes_mes'] ?? 0,
      ordenesFinalizadasMes: json['ordenes_finalizadas_mes'] ?? 0,
      ordenesActivasActual: json['ordenes_activas_actual'] ?? 0,
      ingresosMes: (json['ingresos_mes'] as num?)?.toDouble() ?? 0.0,
      ingresoPromedioOrden:
          (json['ingreso_promedio_orden'] as num?)?.toDouble() ?? 0.0,
      porEstado: _parseCounts(json['por_estado']),
      porMecanico: _parseCounts(json['por_mecanico']),
      porServicio: _parseCounts(json['por_servicio']),
      ordenes: json['ordenes'] is List ? json['ordenes'] as List : [],
    );
  }
}
