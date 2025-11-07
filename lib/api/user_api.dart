import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/sys_user.dart';

class UserAPI {
  static const String baseUrl = 'https://focsonmyfinger.com/myinsurAPI/api';


  static Future<Map<String, dynamic>?> verifyByPhone(String phoneNo, String password) async {
    final url = Uri.parse('$baseUrl/SysUser/loginByPhone/$phoneNo/$password');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<SysUser?> getUserById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sysuser/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return SysUser.fromJson(jsonDecode(response.body));
    }
    return null;
  }


  static Future<bool> updateUserDetails(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sysUser/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> resetPassword(int userId, String newPassword) async {
    final url = Uri.parse('$baseUrl/sysuser/updatePassword');

    final body = jsonEncode({
      'userID'      : userId,
      'newPassword' : newPassword,
    });

    try {
      final res = await http.put(url,
          headers: {'Content-Type': 'application/json'},
          body: body);

      if (res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  static Future<SysUser?> getUserByPhoneNo(String phoneNo) async {
    final url = Uri.parse('$baseUrl/sysuser/getByPhoneNo?phoneNo=$phoneNo');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return SysUser.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }
}
