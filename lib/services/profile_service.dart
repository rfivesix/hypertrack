// lib/services/profile_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
// Important for ImageCache
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing user profile information, such as the profile picture.
///
/// Implements [ChangeNotifier] to allow UI components to react to profile changes.
class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();

  /// Returns the singleton instance of [ProfileService].
  factory ProfileService() => _instance;
  ProfileService._internal();

  String? _profileImagePath;

  /// The local file path to the user's profile image.
  String? get profileImagePath => _profileImagePath;

  /// A counter that increments whenever the profile image is updated.
  ///
  /// Used to force image providers to bypass cache and redraw the image.
  int cacheBuster = 0;

  bool _isPickerActive = false;
  static const String _profileImageKey = 'profileImagePath';

  /// Initializes the service by loading the saved profile image path from storage.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString(_profileImageKey);

    // Validation: does the file really still exist?
    if (_profileImagePath != null) {
      final file = File(_profileImagePath!);
      if (!await file.exists()) {
        _profileImagePath = null;
        await prefs.remove(_profileImageKey);
      }
    }
    notifyListeners();
  }

  /// Opens the gallery to pick a new profile image and saves it locally.
  ///
  /// Copy the image to the application's document directory to ensure it persists.
  Future<void> pickAndSaveProfileImage() async {
    if (_isPickerActive) return;
    _isPickerActive = true;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        const fileName = 'profile_image.jpg';
        final localPath = '${appDir.path}/$fileName';
        final targetFile = File(localPath);

        // 1. Important: evict the old image from the Flutter cache
        // before writing the new one.
        try {
          await FileImage(targetFile).evict();
        } catch (e) {
          // Ignore if it was not in the cache.
        }

        // 2. Copy/overwrite file
        await File(pickedFile.path).copy(localPath);

        // 3. Save path
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_profileImageKey, localPath);

        _profileImagePath = localPath;
        cacheBuster++; // Forces the widget to redraw.
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fehler beim Bild-Upload: $e');
    } finally {
      _isPickerActive = false;
    }
  }

  /// Deletes the current profile image from both storage and disk.
  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentPath = prefs.getString(_profileImageKey);

    if (currentPath != null) {
      // 1. Remove from cache (important).
      try {
        await FileImage(File(currentPath)).evict();
      } catch (e) {
        // Fine if it was not in the cache.
      }

      // 2. Update UI immediately (optimistic UI update)
      _profileImagePath = null;
      await prefs.remove(_profileImageKey);
      cacheBuster++;
      notifyListeners();

      // 3. Physically delete file
      try {
        final imageFile = File(currentPath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        debugPrint('Fehler beim Löschen der Datei: $e');
      }
    }
  }
}
