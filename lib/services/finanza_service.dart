import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../models/finanza_model.dart';

class FinanzaService {
  Future<Map<String, dynamic>> obtenerFinanzasPorVehiculo(
    int vehiculoId,
  ) async {
    try {
      final response = await DioClient.dio.get('/finanzas/$vehiculoId');

      if (response.statusCode == 200) {
        final List<dynamic> lista = response.data['finanzas'] ?? [];
        final double total = double.parse(response.data['total'].toString());

        final finanzas = lista
            .map((json) => FinanzaModel.fromJson(json))
            .toList();

        return {'finanzas': finanzas, 'total': total};
      }
      return {'finanzas': <FinanzaModel>[], 'total': 0.0};
    } catch (e) {
      print("Error al obtener finanzas: $e");
      return {'finanzas': <FinanzaModel>[], 'total': 0.0};
    }
  }
}
