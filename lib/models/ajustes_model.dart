class AjustesModel {
  final int? id;
  final int? idCliente;
  final String tema;
  final bool notificacionesActivas;

  AjustesModel({
    this.id,
    this.idCliente,
    required this.tema,
    required this.notificacionesActivas,
  });

  factory AjustesModel.fromJson(Map<String, dynamic> json) {
    return AjustesModel(
      id: json['id'],
      idCliente: json['id_cliente'],
      tema: json['tema'] ?? 'claro',
      // Laravel devuelve 1 o 0 para booleano
      notificacionesActivas: json['notificaciones_activas'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tema': tema,
      'notificaciones_activas': notificacionesActivas ? 1 : 0,
    };
  }
}
