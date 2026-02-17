import '../utils/dio_client.dart';

class VehService {
  Future<List<dynamic>> obtenerMisVehiculos() async {
    await DioClient.setTokenHeader(); // 🔹 aseguramos que el token esté
    final response = await DioClient.dio.get("/mis-vehiculos");
    return response.data;
  }
}