class EtapaServicioModel{
final String estado;
final String id_mecanico;
final int tiempoEstimado;
final String aprobacionCliente;

EtapaServicioModel({
  required this.estado,
  required this.id_mecanico,
  required this.tiempoEstimado,
  required this.aprobacionCliente,
  });

  factory EtapaServicioModel.fromJson(Map<String, dynamic> json) {
    return EtapaServicioModel(
      estado: json['estado'],
      id_mecanico: json['id_mecanico'],
      tiempoEstimado: json['tiempoEstimado'],
      aprobacionCliente: json['aprobacionCliente'],
    );
  }
}