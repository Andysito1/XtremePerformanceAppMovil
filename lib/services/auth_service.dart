import 'package:dio/dio.dart';
import 'package:xtreme_performance/utils/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<String?> login(String correo, String password) async {
    try {
      final response = await DioClient.dio.post(
        "/login",
        data: {
          "correo": correo,
          "password": password,
        },
      );

      final token = response.data["token"];

      if (token != null) {
        // 🔹 Guardamos token en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }

      return token;
    } on DioException catch (e) {
      print("Error en login: ${e.response?.data}");
      return null;
    }
  }
}
