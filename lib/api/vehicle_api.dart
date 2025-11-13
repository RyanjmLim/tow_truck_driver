import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model/vehicle.dart';

class VehicleAPI {
  //static const String baseUrl = 'http://10.0.2.2:5209/api/Vehicle';
  static const String baseUrl = 'https://focsonmyfinger.com/myinsurAPI/api/Vehicle';

  static Future<bool> addVehicle({
    required String plateNo,
    required String brand,
    required String model,
    required String colour,
    int? manuYear,
    required String vehicleUse,
    required String registrationCard,
    required String imgCar,
    required int userID,
    required String remark,
    required String status,
    String? companyName,
    String? companyRegNo,
    String? imgDirectorNric,
    String? imgDirectorLicense,
  }) async {
    final body = {
      "plateNo": plateNo,
      "brand": brand,
      "model": model,
      "colour": colour,
      "vehicleUse": vehicleUse,
      "registrationCard": registrationCard,
      "imgCar": imgCar,
      "userId": userID,
      "remark": remark,
      "status": status,
      "companyName": companyName ?? '',
      "companyRegNo": companyRegNo ?? '',
      "imgDirectorNric": imgDirectorNric ?? '',
      "imgDirectorLicense": imgDirectorLicense ?? '',
      "isVerified": 1,
      if (manuYear != null) "manuYear": manuYear,
    };

    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print("✅ Vehicle added: ${response.body}");
        return true;
      } else {
        print("❌ Failed to add vehicle: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception in addVehicle: $e");
      return false;
    }
  }

  static Future<List<Vehicle>> getByUserId(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/getByUserId/$userId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        List<Vehicle> vehicles = data.map((e) => Vehicle.fromJson(e)).toList();

        return vehicles;
      } else if (response.statusCode == 404) {
        print('⚠️ No vehicles found for user $userId');
        return [];
      } else {
        throw Exception('❌ Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('❌ Network or server error: $e');
    }
  }

  static Future<Vehicle?> getVehicleById(int vehicleId) async {
    final response = await http.get(Uri.parse('$baseUrl/$vehicleId'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      print('📦 getVehicleById response: $decoded');
      return Vehicle.fromJson(decoded);
    } else {
      print("❌ Failed to get vehicle: ${response.statusCode}");
      return null;
    }
  }

  static Future<bool> updateStatus(int vehicleId, String newStatus) async {
    final url = Uri.parse('$baseUrl/updateStatus/$vehicleId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newStatus), // Just a plain string in the body
      );

      if (response.statusCode == 200) {
        print("✅ Vehicle status updated to $newStatus");
        return true;
      } else {
        print("❌ Failed to update vehicle status: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception while updating vehicle status: $e");
      return false;
    }
  }

  static Future<bool> updateVehicle({
    required int id,
    required String model,
    required String plate,
    required String colour,
    required String vehicleUse,
    required String remark,
    required String brand,
    required int manuYear,
    required int userId,
    required int isVerified, // now using int not bool
    String? vehiclePhoto,
    String? roadTaxDoc,
    File? insuranceDoc,
  }) async {
    final url = Uri.parse('$baseUrl/update');

    final body = {
      "id": id,
      "model": model,
      "plateNo": plate,
      "colour": colour,
      "vehicleUse": vehicleUse,
      "remark": remark,
      "brand": brand,
      "manuYear": manuYear,
      "registrationCard": roadTaxDoc != null ? roadTaxDoc.split('/').last : "",
      "imgCar": vehiclePhoto != null ? vehiclePhoto.split('/').last : "",
      "isVerified": isVerified,
      "userId": userId,
    };
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ Vehicle updated successfully.");
        return true;
      } else {
        print("❌ Update failed:");
        print("Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print('❌ Exception during update: $e');
      return false;
    }
  }

  static Future<bool> deleteVehicle(int vehicleId) async {
    final url = Uri.parse('$baseUrl/delete/$vehicleId');

    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Delete error: $e');
      return false;
    }
  }

}
