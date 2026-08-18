class EvidenciaModel {
  final int id;
  final String tipo; // 'imagen' | 'video'
  final String url;
  final String? descripcion;

  EvidenciaModel({
    required this.id,
    required this.tipo,
    required this.url,
    this.descripcion,
  });

  factory EvidenciaModel.fromJson(Map<String, dynamic> json) {
    return EvidenciaModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      tipo: json['tipo'] ?? 'imagen',
      url: json['url'] ?? json['archivo_url'] ?? '',
      descripcion: json['descripcion'],
    );
  }
}
