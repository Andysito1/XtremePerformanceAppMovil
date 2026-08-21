import '../utils/dio_client.dart';
import '../models/solicitud_reserva_model.dart';

class SolicitudReservaService {
  Future<List<SolicitudReservaModel>> getPendientes() async {
    try {
      await DioClient.setTokenHeader();
      final response = await DioClient.dio.get(
        '/solicitudes-reserva',
        queryParameters: {'estado': 'pendiente'},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((json) => SolicitudReservaModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener solicitudes de reserva: $e');
      return [];
    }
  }

  Future<int> getPendientesCount() async {
    try {
      await DioClient.setTokenHeader();
      final response = await DioClient.dio.get(
        '/solicitudes-reserva/pendientes-count',
      );
      return response.data['count'] ?? 0;
    } catch (e) {
      print('Error al obtener el conteo de solicitudes pendientes: $e');
      return 0;
    }
  }
}
