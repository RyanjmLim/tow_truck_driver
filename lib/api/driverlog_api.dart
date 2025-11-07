
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/DriverCaseInfo.dart';
import '../model/DriverLogStatusUpdate.dart';

class DriverLogApi{
  static const String baseUrl = 'https://focsonmyfinger.com/myinsurAPI/api';

  // GET /currentCaseInfo/{userId}
  static Future<DriverCaseInfo?> getCurrentCaseInfo(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/currentCaseInfo/$userId'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return DriverCaseInfo.fromJson(jsonData);
    } else {
      return null;
    }
  }

  // POST /updateStatusByDriverIDAndCaseID
  static Future<bool> updateDriverLogStatus(DriverLogStatusUpdate request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/updateStatusByDriverIDAndCaseID'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
