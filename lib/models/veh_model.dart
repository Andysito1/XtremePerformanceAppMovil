class VehiculoModel {
  final int id;
  final int idCliente;
  final String marca;
  final String modelo;
  final int anio;
  final String placa;
  final String? imagen;

  VehiculoModel({
    required this.id,
    required this.idCliente,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.placa,
    this.imagen,
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'],
      idCliente: json['id_cliente'],
      marca: json['marca'],
      modelo: json['modelo'],
      anio: json['anio'],
      placa: json['placa'],
      imagen: json['imagen'],
    );
  }
}
