import '../utils/dio_client.dart';
import '../models/dashboard_resumen_model.dart';

class DashboardService {
  Future<DashboardResumenModel?> obtenerResumen({
    required int anio,
    required int mes,
  }) async {
    try {
      await DioClient.setTokenHeader();
      final response = await DioClient.dio.get(
        '/dashboard/resumen',
        queryParameters: {'anio': anio, 'mes': mes},
      );
      return DashboardResumenModel.fromJson(response.data);
    } catch (e) {
      print('Error al obtener el resumen del dashboard: $e');
      return null;
    }
  }
}
