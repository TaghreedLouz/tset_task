import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../model/contact.dart';

class ContactService {
  static const String baseUrl =
      'https://jsonplaceholder.typicode.com/users';

  final http.Client _client;

  ContactService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<Contact>> getContacts() async {
    try {
      final response = await _client.get(
        Uri.parse(baseUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
        jsonDecode(response.body) as List<dynamic>;

        return data.map((item) {
          return Contact.fromJson(
            item as Map<String, dynamic>,
          );
        }).toList();
      }

      throw Exception(
        'فشل تحميل جهات الاتصال: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('خطأ أثناء جلب جهات الاتصال: $e');
    }
  }

  Future<Contact> addContact(Contact contact) async {
    try {
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(contact.toJson()),
      );

      if (response.statusCode == 201) {
        return Contact.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw Exception(
        'فشل إضافة جهة الاتصال: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('خطأ أثناء الإضافة: $e');
    }
  }

  Future<Contact> updateContact(Contact contact) async {
    if (contact.id == null) {
      throw ArgumentError('معرّف جهة الاتصال مطلوب للتعديل');
    }

    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/${contact.id}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(contact.toJson()),
      );

      if (response.statusCode == 200) {
        return Contact.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw Exception(
        'فشل تعديل جهة الاتصال: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('خطأ أثناء التعديل: $e');
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        throw Exception(
          'فشل حذف جهة الاتصال: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('خطأ أثناء الحذف: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}