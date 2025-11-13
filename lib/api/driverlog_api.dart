
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/DriverCaseInfo.dart';
import '../model/DriverLogStatusUpdate.dart';

class DriverLogAPI{
  static const String baseUrl = 'https://focsonmyfinger.com/myinsurAPI/api';

  // GET /currentCaseInfo/{userId}
  static Future<DriverCaseInfo?> getCurrentCaseInfo(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/DriverLog/currentCaseInfo/$userId'));

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
      Uri.parse('$baseUrl/DriverLog/updateStatusByDriverIDAndCaseID'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> assignDriverLog({
    required int driverId,
    required int vehicleId,
    required int companySysUserId,
    required String status,
    required int caseId,
  }) async {
    final body = jsonEncode({
      "driverID": driverId,
      "vehicleID": vehicleId,
      "companySysUserID": companySysUserId,
      "status": status,
      "caseID": caseId,
      "eta": null
    });

    final response = await http.post(
      Uri.parse('$baseUrl/DriverLog/add'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response.statusCode == 200;
  }

  static Future<bool> completeDriverLog({
    required int driverId,
    required int vehicleId,
    required int caseId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/DriverLog/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'driverID': driverId,
        'vehicleID': vehicleId,
        'caseID': caseId,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<String>> getAllDriverStatuses(int caseId) async {
    final url = Uri.parse('$baseUrl/DriverLog/getDriverLogDetails/$caseId');

    final response = await http.get(url);
    print("DEBUG >> API URL: $url");
    print("DEBUG >> Raw API response: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final statuses = data
          .map((e) => e['driverLog']?['status']?.toString().trim() ?? '')
          .where((status) => status.isNotEmpty)
          .toList();

      // Debug print each driver and their status
      for (var i = 0; i < data.length; i++) {
        final driverName = data[i]['sysUser']?['fullName'] ?? 'Unknown Driver';
        final driverStatus = data[i]['driverLog']?['status'] ?? 'No Status';
        print("DEBUG >> Driver ${i + 1} ($driverName) status: $driverStatus");
      }

      return statuses;
    }

    return [];
  }
}
