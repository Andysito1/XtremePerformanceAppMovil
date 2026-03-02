class EtapaModel {
  final String titulo;
  final String descripcion;
  final String estado; // "Pendiente", "En Progreso", "Completado"
  final String? fecha;
  final String tipo; // "DIAGNOSTICO", "REPARACION", "PRUEBAS", "FINALIZACION"

  EtapaModel({
    required this.titulo,
    required this.descripcion,
    required this.estado,
    this.fecha,
    required this.tipo,
  });

  factory EtapaModel.fromJson(Map<String, dynamic> json) {
    return EtapaModel(
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      estado: json['estado'] ?? 'Pendiente',
      fecha: json['fecha'],
      tipo: json['tipo'] ?? 'GENERICO',
    );
  }
}
