import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _assistantMemoryKey = 'assistant_memory_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _chatHistoryKey = 'assistant_chat_history';
  static const String _profileNameKey = 'profile_name';
  static const String _profilePhoneKey = 'profile_phone';
  static const String _profileGenderKey = 'profile_gender';
  static const String _profileAgeKey = 'profile_age';
  static const String _profileImageKey = 'profile_image';

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

  static Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_profileNameKey) ?? '',
      'phone': prefs.getString(_profilePhoneKey) ?? '',
      'gender': prefs.getString(_profileGenderKey) ?? '',
      'age': prefs.getString(_profileAgeKey) ?? '',
      'image': prefs.getString(_profileImageKey) ?? '',
    };
  }

  static Future<void> saveProfile({
    required String name,
    required String phone,
    required String gender,
    required String age,
    String? imageBase64,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, name);
    await prefs.setString(_profilePhoneKey, phone);
    await prefs.setString(_profileGenderKey, gender);
    await prefs.setString(_profileAgeKey, age);
    if (imageBase64 != null) {
      await prefs.setString(_profileImageKey, imageBase64);
    }
  }

  static Future<void> saveProfileImage(String imageBase64) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, imageBase64);
  }
}
