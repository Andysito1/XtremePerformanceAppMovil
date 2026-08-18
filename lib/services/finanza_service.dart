import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../models/finanza_model.dart';
import '../models/historial_orden_model.dart';

class FinanzaService {
  Future<Map<String, dynamic>> obtenerFinanzasPorVehiculo(
    int vehiculoId, {
    int? ordenId,
  }) async {
    try {
      await DioClient.setTokenHeader();
      final String url = ordenId != null
          ? '/finanzas/$vehiculoId?orden_id=$ordenId'
          : '/finanzas/$vehiculoId';
      final response = await DioClient.dio.get(url);

      print("DEBUG: Respuesta Finanzas Body: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> finanzasRaw = response.data['finanzas'] ?? [];
        final List<dynamic> ordenesRaw = response.data['ordenes'] ?? [];

        final List<FinanzaModel> finanzas = finanzasRaw
            .map((f) => FinanzaModel.fromJson(f))
            .toList();

        final List<HistorialOrdenModel> ordenes = ordenesRaw
            .map((o) => HistorialOrdenModel.fromJson(o))
            .toList();

        // Calculamos el total sumando el propio desglose en vez de confiar en
        // el campo 'total' del backend (costo_total de la orden), que puede
        // desincronizarse del detalle real de finanzas_servicio.
        final double totalCalculado = finanzas.fold(
          0.0,
          (sum, f) => sum + f.monto,
        );

        return {
          'finanzas': finanzas,
          'total': totalCalculado,
          'ordenes': ordenes,
          'orden_seleccionada': response.data['orden_seleccionada'],
        };
      }
      return {'finanzas': [], 'total': 0.0, 'ordenes': []};
    } catch (e) {
      print("Error en FinanzaService: $e");
      return {'finanzas': [], 'total': 0.0, 'ordenes': []};
    }
  }
}
