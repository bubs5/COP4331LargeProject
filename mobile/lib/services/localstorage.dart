import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService{
  static Future<void> saveList(String key, List<Map<String, dynamic>> data) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<List<dynamic>> getList(String key) async{
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    return jsonDecode(raw);
  }

  static Future<void> saveString(String key, String value) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}