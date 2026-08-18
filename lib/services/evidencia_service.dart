import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../models/evidencia_model.dart';

class EvidenciaService {
  /// Lista las evidencias de una etapa. Usado tanto por el cliente (lectura)
  /// como por el mecánico (para refrescar tras subir una nueva).
  Future<List<EvidenciaModel>> obtenerPorEtapa(int idEtapa) async {
    try {
      await DioClient.setTokenHeader();
      final response = await DioClient.dio.get(
        '/etapa-servicio/$idEtapa/evidencias',
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => EvidenciaModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener evidencias: $e');
      return [];
    }
  }

  /// Sube una evidencia (foto) para la etapa indicada. Solo permitido por el
  /// backend si esa etapa está actualmente 'en_proceso' y pertenece al
  /// mecánico autenticado (o es ADMIN).
  Future<bool> subirEvidencia(
    int idEtapa,
    File archivo, {
    String? descripcion,
  }) async {
    try {
      await DioClient.setTokenHeader();
      final nombreArchivo = archivo.path.split('/').last;
      final formData = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(
          archivo.path,
          filename: nombreArchivo,
        ),
        if (descripcion != null && descripcion.isNotEmpty)
          'descripcion': descripcion,
      });

      final response = await DioClient.dio.post(
        '/etapa-servicio/$idEtapa/evidencias',
        data: formData,
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      print('Error al subir evidencia: ${e.response?.data}');
      return false;
    } catch (e) {
      print('Error inesperado al subir evidencia: $e');
      return false;
    }
  }
}
