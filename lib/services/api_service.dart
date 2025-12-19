import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://YOUR_SERVER_IP:4000/api';

  static Future<String> adminLogin(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid credentials');
    }

    final data = jsonDecode(response.body);
    return data['token'];
  }
  static Future<String> createEvent(
      String name,
      String date,
      String token,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/event'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'event_date': date,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create event');
    }

    return jsonDecode(response.body)['eventId'];
  }

  static Future<Map<String, dynamic>> createService(
      String eventId,
      String serviceCode,
      String serviceTime,
      String token,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/service'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'event_id': eventId,
        'service_code': serviceCode,
        'service_time': serviceTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create service');
    }

    return jsonDecode(response.body);
  }
  static Future<Map<String, dynamic>> getAttendance(
      String serviceId,
      String token,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/attendance/service/$serviceId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }

}
