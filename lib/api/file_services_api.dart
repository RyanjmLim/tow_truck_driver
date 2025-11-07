import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileServicesAPI {
  static const String baseUrl = 'https://focsonmyfinger.com/myinsurAPI/api/FileServices';

  static Future<String?> uploadFile(File file, String fName,
      String directory) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'))
        ..fields['fName'] = fName
        ..fields['directory'] = directory
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('application', 'octet-stream'),
        ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return fName; // Return filename for database
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  static Future<String?> uploadBreakdownProof(File file) async {
    String fName = DateTime.now().millisecondsSinceEpoch.toString() + "_bd.jpg";
    return await uploadFile(file, fName, "inc_bd");
  }

  static Future<String?> uploadPoliceStationProof(File file) async {
    String fName = DateTime.now().millisecondsSinceEpoch.toString() + "_ps.jpg";
    return await uploadFile(file, fName, "inc_ps");
  }

  static Future<String?> uploadWorkshopProof(File file) async {
    String fName = DateTime.now().millisecondsSinceEpoch.toString() + "_ws.jpg";
    return await uploadFile(file, fName, "inc_ws");
  }


}

