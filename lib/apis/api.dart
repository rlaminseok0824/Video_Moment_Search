import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'dart:io';

Future<List<List<String>>> getTimeStamps(String videoId, String text) async {
  await Future.delayed(const Duration(milliseconds: 500));

  return [
    ["10", "25", "0.8"],
    ["30", "40", "0.5"],
  ];
}

Future<String> uploadFileToServer(XFile file) async {
  try {
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://localhost:8080/upload'));
    request.headers['Content-Type'] = 'multipart/form-data';
    request.files.add(
      http.MultipartFile.fromBytes('file', await file.readAsBytes(),
          filename: 'input.mp4'),
    );

    var response = await request.send();
    if (response.statusCode == 200) {
      print('File uploaded successfully.');
      var responseBody = await response.stream.bytesToString();
      return responseBody;
    } else {
      print('File upload failed with status: ${response.statusCode}.');
      return '';
    }
  } catch (e) {
    print('An error occurred while uploading the file: $e');
    return '';
  }
}
