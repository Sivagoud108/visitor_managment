import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_exception.dart';
import '../models/visitor.dart';

class VisitorApiService {
  
    static const String apiBaseUrl =
      'https://crudcrud.com/api/10173d157646460791d273ae7aa90c7b/visitors';
  /// GET all visitors.
  Future<List<Visitor>> fetchVisitors() async {
    try {
      final response = await http.get(Uri.parse(apiBaseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Visitor.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw AppException('Failed to load visitors (${response.statusCode})');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Network error: $e');
    }
  }

  /// POST a new visitor. Returns the created visitor with server id.
  Future<Visitor> createVisitor(Visitor visitor) async {
    try {
      final response = await http.post(
        Uri.parse(apiBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(visitor.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Visitor.fromJson(data);
      }
      throw AppException(
        'Failed to register visitor (${response.statusCode})',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Network error: $e');
    }
  }

  /// PUT an existing visitor (used in edit mode).
  Future<Visitor> updateVisitor(String id, Visitor visitor) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(visitor.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return visitor;
      }
      throw AppException('Failed to update visitor (${response.statusCode})');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Network error: $e');
    }
  }

  /// DELETE a visitor by id.
  Future<void> deleteVisitor(String id) async {
    try {
      final response = await http.delete(Uri.parse('$apiBaseUrl/$id'));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw AppException('Failed to delete visitor (${response.statusCode})');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Network error: $e');
    }
  }

  /// GET /visitors/{id}
  Future<Visitor> fetchVisitorById(String id) async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Visitor.fromJson(data);
      }
      if (response.statusCode == 404) {
        throw AppException('Visitor not found');
      }
      throw AppException('Failed to load visitor (${response.statusCode})');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Network error: $e');
    }
  }
}

