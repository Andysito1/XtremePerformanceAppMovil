import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../models/ajustes_model.dart';

class AjustesService {
  // Obtener la configuración del usuario actual
  Future<AjustesModel?> obtenerConfiguracion() async {
    try {
      await DioClient.setTokenHeader();
      final response = await DioClient.dio.get('/configuracion');

      if (response.statusCode == 200 && response.data != null) {
        // Si el backend devuelve un objeto (la configuración existente)
        if (response.data is Map<String, dynamic> && response.data.isNotEmpty) {
          return AjustesModel.fromJson(response.data);
        }
      }
      // Si no hay configuración, devuelve null
      return null;
    } catch (e) {
      print("Error al obtener la configuración: $e");
      // Si el error es 404 (no encontrado), es normal si el usuario es nuevo.
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  // Guardar o actualizar la configuración del usuario
  Future<bool> guardarConfiguracion(AjustesModel ajustes) async {
    try {
      await DioClient.setTokenHeader();
      // Usamos POST, el backend se encargará de crear o actualizar (upsert)
      final response = await DioClient.dio.post(
        '/configuracion',
        data: ajustes.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error al guardar la configuración: $e");
      return false;
    }
  }
}
