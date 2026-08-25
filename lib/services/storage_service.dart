import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _assistantMemoryKey = 'assistant_memory_enabled';

  // Save Assistant preference setting locally
  static Future<void> saveAssistantPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_assistantMemoryKey, enabled);
  }

  // Retrieve Assistant preference setting
  static Future<bool> getAssistantPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_assistantMemoryKey) ?? true;
  }
}