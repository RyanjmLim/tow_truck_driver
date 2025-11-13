import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/incidentcase.dart';
import '../model/IncidentCaseOwnerDetails.dart';
import '../model/DriverCaseInfo.dart';
import '../model/DriverLogStatusUpdate.dart';
import '../model/DriverLogETAUpdate.dart';
import '../model/driver_log.dart';
import '../model/workshop_panel.dart';

class IncidentCaseAPI {
  static const String baseUrl = 'https://focsonmyfinger.com/myinsurAPI/api';
  // static const String baseUrl = 'http://10.0.2.2:5209/api';

  static Future<IncidentCase?> getByCaseId(int caseId) async {
    final url = Uri.parse('$baseUrl/IncidentCase/getByCaseId/$caseId');

    final response = await http.get(url);
    print('Response: ${response.statusCode}, Body: ${response.body}');

    if (response.statusCode == 200) {
      return IncidentCase.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  static Future<bool> updateCaseStatus(int caseId, String status) async {
    final url = Uri.parse('$baseUrl/IncidentCase/UpdateCaseStatus');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'caseID': caseId,
        'status': status,
      }),
    );

    print('Update status response: ${response.statusCode}');
    return response.statusCode == 200;
  }

  static Future<bool> updateCaseDetails({
    required int caseId,
    required String newStatus,
    String? policeStationLocation,
    String? proofAtBreakdownPhoto,
    String? proofAtPoliceStationPhoto,
    String? proofAtWorkshopPhoto,
  }) async {
    final url = Uri.parse('$baseUrl/IncidentCase/update');
    final body = {
      'caseID': caseId,
      'status': newStatus,
      if (policeStationLocation != null) 'policeStationLocation': policeStationLocation,
      if (proofAtBreakdownPhoto != null) 'proofAtBreakdownPhoto': proofAtBreakdownPhoto,
      if (proofAtPoliceStationPhoto != null) 'proofAtPoliceStationPhoto': proofAtPoliceStationPhoto,
      if (proofAtWorkshopPhoto != null) 'proofAtWorkshopPhoto': proofAtWorkshopPhoto,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  static Future<bool> updateOngoingStatus({
    required int caseID,
    required String status,
    String? policeStationLocation,
    String? proofAtBreakdownPhoto,
    String? proofAtPoliceStationPhoto,
    String? proofAtWorkshopPhoto,
    DateTime? arrivedAtBreakdownTime,
    DateTime? arrivedAtPoliceStationTime,
    DateTime? arrivedAtWorkshopTime,

  }) async {
    final url = Uri.parse("$baseUrl/IncidentCase/updateOngoingStatus");

    final body = jsonEncode({
      "caseID": caseID,
      "status": status,
      "policeStationLocation": policeStationLocation,
      "proofAtBreakdownPhoto": proofAtBreakdownPhoto,
      "proofAtPoliceStationPhoto": proofAtPoliceStationPhoto,
      "proofAtWorkshopPhoto": proofAtWorkshopPhoto,
      "arrivedAtBreakdownTime": arrivedAtBreakdownTime?.toIso8601String(),
      "arrivedAtPoliceStationTime": arrivedAtPoliceStationTime?.toIso8601String(),
      "arrivedAtWorkshopTime": arrivedAtWorkshopTime?.toIso8601String(),

    });

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );


      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<IncidentCaseOwnerDetails?> getOwnerDetails(int caseId) async {
    final url = Uri.parse('$baseUrl/IncidentCase/getOwnerDetails/$caseId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return IncidentCaseOwnerDetails.fromJson(data);
    } else {

      return null;
    }
  }
  static Future<DriverCaseInfo?> getCurrentCaseInfo(int userId) async {
    final url = Uri.parse('$baseUrl/DriverLog/currentCaseInfo/$userId');
    final response = await http.get(url);
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
      Uri.parse('$baseUrl/DriverLog/updateStatusByDriverLogID'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {

      return false;
    }
  }
  static Future<bool> updateETAByDriverLogID(DriverLogETAUpdate request) async {
    final url = Uri.parse('$baseUrl/DriverLog/updateETAByDriverLogID');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<DriverLog?> getDriverLogByID(int driverLogID) async {
    final url = Uri.parse('$baseUrl/DriverLog/getByDriverLogID/$driverLogID');

    try {

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return DriverLog.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<WorkshopPanel?> getByWorkshopId(int workshopId) async {
    final url = Uri.parse('$baseUrl/WorkshopPanel/$workshopId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return WorkshopPanel.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }

  static Future<List<DriverCaseInfo>> getHistoryByUserID(int userId) async {
    final url = Uri.parse('$baseUrl/DriverLog/getHistoryByUserID/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => DriverCaseInfo.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load driver history");
    }
  }

}


