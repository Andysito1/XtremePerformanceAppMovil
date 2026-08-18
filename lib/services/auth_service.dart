import 'package:dio/dio.dart';
import 'package:xtreme_performance/utils/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginResult {
  final String token;
  final String rolNombre;

  LoginResult({required this.token, required this.rolNombre});
}

class AuthService {
  Future<LoginResult?> login(String correo, String password) async {
    try {
      final response = await DioClient.dio.post(
        "/login",
        data: {
          "correo": correo,
          "password": password,
        },
      );

      final token = response.data["token"];
      final usuario = response.data["user"];
      final rolNombre = (usuario is Map && usuario['rol'] is Map)
          ? usuario['rol']['nombre'] as String? ?? 'CLIENTE'
          : 'CLIENTE';

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_role', rolNombre);
      }

      if (token == null) return null;
      return LoginResult(token: token, rolNombre: rolNombre);
    } on DioException catch (e) {
      print("Error en login: ${e.response?.data}");
      return null;
    }
  }
}
