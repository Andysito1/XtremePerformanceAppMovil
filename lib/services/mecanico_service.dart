import '../utils/dio_client.dart';

class MecanicoService {
  /// Órdenes de servicio asignadas al mecánico autenticado, con sus etapas
  /// y evidencias ya incluidas por el backend.
  Future<List<dynamic>> obtenerMisOrdenes() async {
    try {
      await DioClient.setTokenHeader();
      final response = await DioClient.dio.get('/mis-ordenes');
      return response.data is List ? response.data : [];
    } catch (e) {
      print('Error al obtener las órdenes del mecánico: $e');
      return [];
    }
  }
}
