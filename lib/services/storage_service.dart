import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String notebooksBoxName = 'notebooks';
  static const String flashcardsBoxName = 'flashcards';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(notebooksBoxName);
    await Hive.openBox(flashcardsBoxName);
  }

  // Notebooks
  static List<Map<String, dynamic>> getNotebooks() {
    final box = Hive.box(notebooksBoxName);
    final data = box.get('list', defaultValue: []);
    return List<Map<String, dynamic>>.from(
      data.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<void> saveNotebooks(
    List<Map<String, dynamic>> notebooks,
  ) async {
    final box = Hive.box(notebooksBoxName);
    await box.put('list', notebooks);
  }

  // Flashcards (Folders)
  static List<Map<String, dynamic>> getFolders(String notebookName) {
    final box = Hive.box(flashcardsBoxName);
    final data = box.get(notebookName, defaultValue: []);
    return List<Map<String, dynamic>>.from(
      data.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<void> saveFolders(
    String notebookName,
    List<Map<String, dynamic>> folders,
  ) async {
    final box = Hive.box(flashcardsBoxName);
    await box.put(notebookName, folders);
  }

  // Generic data persistence
  static Future<void> put(String key, dynamic value) async {
    if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
    await Hive.box('settings').put(key, value);
  }

  static dynamic get(String key, {dynamic defaultValue}) {
    if (!Hive.isBoxOpen('settings')) return defaultValue;
    return Hive.box('settings').get(key, defaultValue: defaultValue);
  }
}
