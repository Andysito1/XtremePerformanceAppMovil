class HistorialModel {
  final String titulo;
  final DateTime fecha_fin;
  final int monto;
  final int totalServicios;
  final int totalInvertido;

  HistorialModel({
    required this.titulo,
    required this.fecha_fin,
    required this.monto,
    required this.totalServicios,
    required this.totalInvertido,
  });
}