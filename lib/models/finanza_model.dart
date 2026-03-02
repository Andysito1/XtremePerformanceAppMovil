class FinanzaModel {
  final int id;
  final String concepto;
  final String tipo; // "base" o "adicional"
  final double monto;

  FinanzaModel({
    required this.id,
    required this.concepto,
    required this.tipo,
    required this.monto,
  });

  factory FinanzaModel.fromJson(Map<String, dynamic> json) {
    return FinanzaModel(
      id: json['id'],
      concepto: json['concepto'],
      tipo: json['tipo'],
      // Aseguramos que el monto sea double aunque venga como int o string
      monto: double.parse(json['monto'].toString()),
    );
  }
}
