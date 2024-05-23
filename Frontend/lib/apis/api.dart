import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

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

Future<List<List<String>>> getTimeStamps(String videoId, String text) async {
  try {
    var request = http.Request(
      "GET",
      Uri.parse(
        'http://localhost:8080/retrieve?videoID=$videoId&text=$text',
      ),
    );
    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      return _convertToNestedStringList(responseBody);
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}

List<String> convertJsonArrayStringToList(String jsonArrayString) {
  try {
    // Parse the JSON string to a List<dynamic>
    List<dynamic> parsedList = json.decode(jsonArrayString);

    // Convert each element of the list to a string and collect them into a List<String>
    return parsedList.map((element) => element.toString()).toList();
  } catch (e) {
    return [];
  }
}

List<List<String>> _convertToNestedStringList(String data) {
  data = data.trim();

  RegExp regex = RegExp(r'\[.*?\]');
  Iterable<Match> matches = regex.allMatches(data);
  return matches.map((match) {
    String jsonArrayString = match.group(0)!;
    return convertJsonArrayStringToList(jsonArrayString);
  }).toList();
}
