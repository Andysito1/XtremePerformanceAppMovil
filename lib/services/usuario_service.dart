import 'package:dio/dio.dart';
import '../utils/dio_client.dart';

class UsuarioService {
  Future<List<dynamic>> usuarioInfo() async {
    try {
      await DioClient.setTokenHeader();
      // Cambiamos a /perfil para obtener solo al usuario logueado
      final response = await DioClient.dio.get("/perfil");

      print("Datos Usuario Recibidos: ${response.data}"); // DEBUG

      // Helper para corregir tipos de datos (Laravel envía 1/0 para bool)
      Map<String, dynamic> corregirDatos(dynamic json) {
        final newJson = Map<String, dynamic>.from(json);
        if (newJson['activo'] is int) {
          newJson['activo'] = (newJson['activo'] == 1);
        }
        return newJson;
      }

      // Si el backend devuelve un objeto único (Map), lo convertimos en lista
      if (response.data is Map) {
        return [corregirDatos(response.data)];
      }
      // Por seguridad, si ya es lista, la devolvemos tal cual
      return response.data is List
          ? (response.data as List).map((e) => corregirDatos(e)).toList()
          : [];
    } catch (e) {
      print("Error obteniendo usuario: $e");
      return [];
    }
  }
}
