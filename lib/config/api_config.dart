class ApiConfig {
  // For Android emulator use 10.0.2.2, for physical device use your machine IP
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Headers
  static Map<String, String> headers(String? token) {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }
}
