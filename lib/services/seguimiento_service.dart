import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../models/etapa_model.dart';

class SeguimientoService {
  Future<List<EtapaModel>> obtenerSeguimientoPorVehiculo(int vehiculoId) async {
    try {
      // Asumimos que el endpoint es /seguimiento/{id_vehiculo}
      final response = await DioClient.dio.get('/seguimiento/$vehiculoId');

      // DEBUG: Imprimir respuesta para verificar datos
      print("Respuesta Seguimiento ($vehiculoId): ${response.data}");

      if (response.statusCode == 200) {
        if (response.data['etapas'] != null) {
          final List<dynamic> data = response.data['etapas'];
          return data.map((json) => EtapaModel.fromJson(json)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      // Si hay error o no hay orden activa, retornamos lista vacía o manejamos el error
      print(
        "Error Dio al obtener seguimiento: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return [];
    } catch (e) {
      print("Error inesperado: $e");
      return [];
    }
  }
}
