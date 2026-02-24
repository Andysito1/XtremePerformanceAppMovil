class UsuarioModel{
  final int id;
  final int id_rol;
  final String nombre;
  final String correo;
  final String? password;
  final bool? activo;
  final DateTime created_at;

  UsuarioModel({
    required this.id,
    required this.id_rol,
    required this.nombre,
    required this.correo,
    this.password,
    this.activo,
    required this.created_at,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      id_rol: json['id_rol'],
      nombre: json['nombre'],
      correo: json['correo'],
      password: json['password'],
      activo: json['activo'],
      created_at: json['created_at'],
    );
  }
}