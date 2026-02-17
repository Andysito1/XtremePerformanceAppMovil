import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://127.0.0.1:8000/api", 
      // 10.0.2.2 si usas emulador Android
      headers: {
        "Accept": "application/json",
      },
    ),
  );

  static Future<void> setTokenHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
