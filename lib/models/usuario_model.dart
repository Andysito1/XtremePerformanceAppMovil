class UsuarioModel {
  final int id;
  final int id_rol;
  final String nombre;
  final String correo;
  final String? password;
  final bool? activo;
  final DateTime created_at;
  final String? rolNombre;

  UsuarioModel({
    required this.id,
    required this.id_rol,
    required this.nombre,
    required this.correo,
    this.password,
    this.activo,
    required this.created_at,
    this.rolNombre,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      id_rol: json['id_rol'],
      nombre: json['nombre'],
      correo: json['correo'],
      password: json['password'],
      activo: json['activo'],
      created_at: DateTime.parse(json['created_at']),
      rolNombre: json['rol'] is Map ? json['rol']['nombre'] as String? : null,
    );
  }
}
