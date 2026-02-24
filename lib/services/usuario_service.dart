import '../utils/dio_client.dart';

class UsuarioService {
  Future<List<dynamic>> usuarioInfo() async {
    await DioClient.setTokenHeader(); 
    final response = await DioClient.dio.get("/clientes");
    return response.data;
  }
} 