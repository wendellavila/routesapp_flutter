import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<Map> getFromUrl(String url) async {
  try {
    final response =
        await http.get(Uri.parse(url), headers: {"Accept": "application/json"});
    if (response.statusCode == 200) {
      Map map = jsonDecode(response.body);
      //sort by key
      map = Map.fromEntries(map.entries.toList()
        ..sort((e1, e2) => e1.value['nome'].compareTo(e2.value['nome'])));
      return map;
    } else {
      throw Exception(
          'Failed to load JSON from url "$url". Response Code: ${response.statusCode}.');
    }
  } on Exception catch (e) {
    print(e);
    return {};
  } on Error catch (e) {
    print(e);
    return {};
  }
}

Future<Map> postFromUrl(String url) async {
  try {
    final response = await http
        .post(Uri.parse(url), headers: {"Accept": "application/json"});
    if (response.statusCode == 200) {
      Map map = jsonDecode(response.body);
      //sort by key
      map = Map.fromEntries(map.entries.toList()
        ..sort((e1, e2) => e1.value['nome'].compareTo(e2.value['nome'])));
      return map;
    } else {
      throw Exception(
          'Failed to load JSON from url "$url". Response Code: ${response.statusCode}.');
    }
  } on Exception catch (e) {
    print(e);
    return {};
  } on Error catch (e) {
    print(e);
    return {};
  }
}

Future<Map> readFromAssets(String filename) async {
  String jsonData = await rootBundle.loadString(filename);
  return jsonDecode(jsonData);
}

void writeToLocalPath(String filepath, String content) async {
  try {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final File file = File('${appDocDir.path}/$filepath');
    if (!(await file.exists())) {
      await file.create();
    }
    await file.writeAsString(content);
  } on Exception catch (e) {
    print(e);
  }
}

Future<Map> readFromLocalPath(String filepath) async {
  try {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final File file = File('${appDocDir.path}/$filepath');
    if (!(await file.exists())) {
      await file.create();
      await file.writeAsString("{}");
      return {};
    }
    return jsonDecode(await file.readAsString());
  } on Exception catch (e) {
    print(e);
    return Future.error(e);
  }
}

Future<bool> localFileExists(String filepath) async {
  try {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final File file = File('${appDocDir.path}/$filepath');
    return await file.exists();
  } on Exception catch (e) {
    print(e);
    return Future.error(e);
  }
}
