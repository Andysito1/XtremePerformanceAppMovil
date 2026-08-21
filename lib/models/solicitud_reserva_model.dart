class SolicitudReservaModel {
  final int id;
  final String tipoDocumentoAbreviatura;
  final String numeroDocumento;
  final String correo;
  final String telefono;
  final String vehiculoMarca;
  final String vehiculoModelo;
  final int vehiculoAnio;
  final String problema;
  final String estado;
  final DateTime createdAt;

  SolicitudReservaModel({
    required this.id,
    required this.tipoDocumentoAbreviatura,
    required this.numeroDocumento,
    required this.correo,
    required this.telefono,
    required this.vehiculoMarca,
    required this.vehiculoModelo,
    required this.vehiculoAnio,
    required this.problema,
    required this.estado,
    required this.createdAt,
  });

  factory SolicitudReservaModel.fromJson(Map<String, dynamic> json) {
    return SolicitudReservaModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      tipoDocumentoAbreviatura: json['tipo_documento']?['abreviatura'] ?? '',
      numeroDocumento: json['numero_documento']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      vehiculoMarca: json['vehiculo_marca']?.toString() ?? '',
      vehiculoModelo: json['vehiculo_modelo']?.toString() ?? '',
      vehiculoAnio: json['vehiculo_anio'] is int
          ? json['vehiculo_anio']
          : int.tryParse(json['vehiculo_anio']?.toString() ?? '') ?? 0,
      problema: json['problema']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
