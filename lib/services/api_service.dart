// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.9:3000/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
      await _storage.write(key: 'user_role', value: data['user']['role']);
      return data;
    } else {
      throw Exception('Inscription echouee: ${response.body}');
    }
  }

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
      await _storage.write(key: 'user_role', value: data['user']['role']);
      return data;
    } else {
      throw Exception('Connexion echouee: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['user']['role'] != 'admin') {
        throw Exception('Acces refuse: vous n\'etes pas administrateur');
      }
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(
        key: 'user_id',
        value: data['user']['id'].toString(),
      );
      await _storage.write(key: 'user_name', value: data['user']['name']);
      await _storage.write(key: 'user_role', value: data['user']['role']);
      return data;
    } else {
      throw Exception('Connexion echouee: ${response.body}');
    }
  }

  Future<List<dynamic>> getClinics() async {
    final token = await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/clinics'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Impossible de charger les cliniques');
    }
  }

  Future<Map<String, dynamic>> takeTicket(int clinicId, String priority) async {
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
        'priority': priority,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Impossible de prendre un ticket: ${response.body}');
    }
  }

  Future<List<dynamic>> getQueue(int clinicId) async {
    final token = await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/tickets/clinic/$clinicId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Impossible de charger la file');
    }
  }

  Future<Map<String, dynamic>> callNext(int clinicId) async {
    final token = await _storage.read(key: 'token');
    final response = await http.put(
      Uri.parse('$baseUrl/tickets/clinic/$clinicId/call-next'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Impossible d\'appeler le prochain patient');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await _storage.read(key: 'token');
    final userId = await _storage.read(key: 'user_id');
    final userName = await _storage.read(key: 'user_name');
    final userRole = await _storage.read(key: 'user_role');

    if (token == null) return null;

    return {'id': userId, 'name': userName, 'role': userRole, 'token': token};
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }
}
