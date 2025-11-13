import 'dart:convert';
import 'package:http/http.dart' as http;


import '../model/driver.dart';

class DriverAPI {
  //static const String baseUrl = 'http://10.0.2.2:5209/api/Driver';
  static const String baseUrl = 'https://focsonmyfinger.com/myinsurAPI/api/Driver';

  static Future<bool> addDriver({
    required String status,
    required String licenseNo,
    required String licenseFile,
    required String remark,
    required int sysUserID,
    required int companySysUserID,
  }) async {
    final body = jsonEncode({
      "status": status,
      "licenseNo": licenseNo,
      "licenseFile": licenseFile,
      "remark": remark,
      "sysUserID": sysUserID,
      "CompanySysUserID": companySysUserID
    });

    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print("✅ Driver added: ${response.body}");
      return true;
    } else {
      print("❌ Failed to add driver: ${response.statusCode} - ${response.body}");
      // 🔥 Throw error with response body to trigger catch in Flutter
      throw Exception(response.body);
    }
  }

  static Future<List<Driver>> getByCompanySysUserId(int companySysUserId) async {
    final response = await http.get(Uri.parse('$baseUrl/getbyCompanySysUserId/$companySysUserId'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Driver.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load drivers');
    }
  }

  static Future<Driver?> getById(int id) async {
    final url = Uri.parse('$baseUrl/details/$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Driver.fromJson(jsonData);
      } else {
        print('Failed to load driver: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching driver by ID: $e');
      return null;
    }
  }

  static Future<bool> updateStatus(int driverId, String newStatus) async {
    final url = Uri.parse('$baseUrl/updateStatus/$driverId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newStatus), // 👈 Send plain string JSON like "Active"
      );

      if (response.statusCode == 200) {
        print("✅ Driver status updated to $newStatus");
        return true;
      } else {
        print("❌ Failed to update driver status: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception while updating driver status: $e");
      return false;
    }
  }

  static Future<bool> updateDriver({
    required int id,
    required String status,
    required String licenseNo,
    required int sysUserID,
    int? companySysUserID,
    String? licenseFileName,
  }) async {
    final url = Uri.parse('$baseUrl/update');

    final body = {
      'Id': id,
      'Status': status,
      'LicenseNo': licenseNo,
      'LicenseFile': licenseFileName ?? '',
      'Remark': '',
      'SysUserID': sysUserID,
      'CompanySysUserID': companySysUserID ?? 0,
    };

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('✅ Driver updated successfully');
      return true;
    } else {
      print('❌ Failed to update driver: ${response.statusCode}');
      print('❌ Response body: ${response.body}');
      return false;
    }
  }

  static Future<bool> deleteDriver(int driverId) async {
    final url = Uri.parse('$baseUrl/delete/$driverId');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      print('❌ Delete failed: ${response.body}');
      return false;
    }
  }

}
