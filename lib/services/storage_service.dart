import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _assistantMemoryKey = 'assistant_memory_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _chatHistoryKey = 'assistant_chat_history';

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

  // Save Dark Mode preference setting locally
  static Future<void> saveDarkModePreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  // Retrieve Dark Mode preference setting
  static Future<bool> getDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> saveChatHistory(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chatHistoryKey, messages);
  }

  static Future<List<String>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_chatHistoryKey) ?? [];
  }

  static Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
  }
}
