import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Register new user
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(
        key: 'user_id',
        value: data['user']['id'].toString(),
      );
      await _storage.write(key: 'user_name', value: data['user']['name']);
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(
        key: 'user_id',
        value: data['user']['id'].toString(),
      );
      await _storage.write(key: 'user_name', value: data['user']['name']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Get all clinics
  Future<List<dynamic>> getClinics() async {
    final token = await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/clinics'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load clinics');
    }
  }

  // Take a ticket
  Future<Map<String, dynamic>> takeTicket(int clinicId, String type) async {
    final token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'user_id');

    final response = await http.post(
      Uri.parse('$baseUrl/tickets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'user_id': int.parse(userId!),
        'clinic_id': clinicId,
        'type': type,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to take ticket: ${response.body}');
    }
  }

  // Get queue for a clinic
  Future<List<dynamic>> getQueue(int clinicId) async {
    final token = await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/tickets/clinic/$clinicId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load queue');
    }
  }

  // Call next patient (admin only)
  Future<Map<String, dynamic>> callNext(int clinicId) async {
    final token = await _storage.read(key: 'token');
    final response = await http.put(
      Uri.parse('$baseUrl/tickets/clinic/$clinicId/call-next'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to call next patient');
    }
  }

  // Get current user info
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'user_id');
    final userName = await _storage.read(key: 'user_name');

    if (token == null) return null;

    return {'id': userId, 'name': userName, 'token': token};
  }

  // Logout
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }
}
