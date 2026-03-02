import 'package:intl/intl.dart';

class HistorialOrdenModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String? fechaFin;

  HistorialOrdenModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.fechaFin,
  });

  factory HistorialOrdenModel.fromJson(Map<String, dynamic> json) {
    // Formatear la fecha para que sea más legible
    String? fechaFormateada;
    if (json['fecha_fin'] != null) {
      fechaFormateada = DateFormat(
        'd \'de\' MMMM, y',
        'es',
      ).format(DateTime.parse(json['fecha_fin']));
    }

    return HistorialOrdenModel(
      id: json['id'],
      titulo: json['titulo'] ?? 'Servicio sin título',
      descripcion: json['descripcion'] ?? 'No hay descripción.',
      fechaFin: fechaFormateada,
    );
  }
}
