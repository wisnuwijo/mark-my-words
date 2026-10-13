import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemService {
  static const MethodChannel _channel =
      MethodChannel('com.example.markMyWords/system');

  static final StreamController<String> _fileOpenedController =
      StreamController<String>.broadcast();

  static bool _initialized = false;
  static Map<String, dynamic> _inMemoryPrefs = {};

  /// Stream of file paths opened from macOS Finder (double click or Open With)
  static Stream<String> get onFileOpened => _fileOpenedController.stream;

  /// Initialize listeners for native macOS events
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFileOpened') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          _fileOpenedController.add(path);
        }
      }
    });
  }

  /// Check whether the app is running from /Applications or ~/Applications
  static Future<bool> isRunningFromApplications() async {
    if (!kIsWeb && !Platform.isMacOS) return true;
    try {
      final res = await _channel.invokeMethod<bool>('isRunningFromApplications');
      return res ?? true;
    } catch (e) {
      debugPrint('Error checking isRunningFromApplications: $e');
      return true;
    }
  }

  /// Move MarkMyWord to /Applications and relaunch from there
  static Future<bool> moveToApplicationsFolder() async {
    if (!kIsWeb && !Platform.isMacOS) return false;
    try {
      final res = await _channel.invokeMethod<bool>('moveToApplicationsFolder');
      return res ?? false;
    } catch (e) {
      debugPrint('Error moving to Applications: $e');
      return false;
    }
  }

  /// Reveal /Applications in Finder
  static Future<void> openApplicationsFolder() async {
    if (!kIsWeb && !Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('openApplicationsFolder');
    } catch (e) {
      debugPrint('Error opening Applications folder: $e');
    }
  }

  /// Check whether MarkMyWord is the default viewer for markdown files
  static Future<bool> isDefaultMarkdownViewer() async {
    if (!kIsWeb && !Platform.isMacOS) return true;
    try {
      final res = await _channel.invokeMethod<bool>('isDefaultMarkdownViewer');
      return res ?? false;
    } catch (e) {
      debugPrint('Error checking isDefaultMarkdownViewer: $e');
      return false;
    }
  }

  /// Register MarkMyWord as the default viewer for .md, .markdown files
  static Future<bool> setDefaultMarkdownViewer() async {
    if (!kIsWeb && !Platform.isMacOS) return false;
    try {
      final res = await _channel.invokeMethod<bool>('setDefaultMarkdownViewer');
      return res ?? false;
    } catch (e) {
      debugPrint('Error setting default markdown viewer: $e');
      return false;
    }
  }

  /// Retrieve the file path passed to the app during cold launch
  static Future<String?> getInitialOpenedFile() async {
    if (!kIsWeb && !Platform.isMacOS) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialOpenedFile');
    } catch (e) {
      debugPrint('Error getting initial opened file: $e');
      return null;
    }
  }

  /// Read file content via Cocoa native channel with security scope fallback
  static Future<String?> readFile(String path) async {
    if (!kIsWeb && !Platform.isMacOS) return null;
    try {
      return await _channel.invokeMethod<String>('readFile', path);
    } catch (e) {
      debugPrint('Error reading file via native channel: $e');
      return null;
    }
  }

  // --- Preference helpers ---

  static Future<File?> _getPrefsFile() async {
    if (kIsWeb || !Platform.isMacOS) return null;
    try {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return null;
      final dir = Directory('$home/Library/Application Support/MarkMyWord');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return File('${dir.path}/preferences.json');
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> _loadPrefs() async {
    try {
      final file = await _getPrefsFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        _inMemoryPrefs = Map<String, dynamic>.from(jsonDecode(content) as Map);
      }
    } catch (_) {}
    return _inMemoryPrefs;
  }

  static Future<void> _savePrefs(Map<String, dynamic> prefs) async {
    _inMemoryPrefs = prefs;
    try {
      final file = await _getPrefsFile();
      if (file != null) {
        await file.writeAsString(jsonEncode(prefs));
      }
    } catch (_) {}
  }

  static Future<bool> getShouldPromptMoveToApplications() async {
    final prefs = await _loadPrefs();
    return prefs['dont_prompt_move_to_apps'] != true;
  }

  static Future<void> setDontPromptMoveToApplications(bool value) async {
    final prefs = await _loadPrefs();
    prefs['dont_prompt_move_to_apps'] = value;
    await _savePrefs(prefs);
  }

  static Future<bool> getShouldPromptDefaultViewer() async {
    final prefs = await _loadPrefs();
    return prefs['dont_prompt_default_viewer'] != true;
  }

  static Future<void> setDontPromptDefaultViewer(bool value) async {
    final prefs = await _loadPrefs();
    prefs['dont_prompt_default_viewer'] = value;
    await _savePrefs(prefs);
  }
}
