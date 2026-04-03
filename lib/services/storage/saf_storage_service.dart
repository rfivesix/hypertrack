import 'package:flutter/services.dart';

class SafPickedDirectory {
  const SafPickedDirectory({required this.treeUri, required this.displayPath});

  final String treeUri;
  final String displayPath;
}

class SafStorageService {
  SafStorageService._();

  static final SafStorageService instance = SafStorageService._();

  static const MethodChannel _channel = MethodChannel('hypertrack.storage/saf');

  Future<SafPickedDirectory?> pickDirectory() async {
    final raw = await _channel.invokeMethod<dynamic>('pickDirectory');
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final treeUri = (map['treeUri'] as String?)?.trim();
    final displayPath = (map['displayPath'] as String?)?.trim();
    if (treeUri == null ||
        treeUri.isEmpty ||
        displayPath == null ||
        displayPath.isEmpty) {
      return null;
    }
    return SafPickedDirectory(treeUri: treeUri, displayPath: displayPath);
  }

  Future<String?> writeTextFileToTree({
    required String treeUri,
    required String fileName,
    required String content,
    String mimeType = 'application/json',
  }) async {
    final raw = await _channel.invokeMethod<dynamic>(
      'writeTextFileToTree',
      <String, dynamic>{
        'treeUri': treeUri,
        'fileName': fileName,
        'content': content,
        'mimeType': mimeType,
      },
    );
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return map['displayPath'] as String?;
  }

  Future<void> pruneAutoBackupsInTree({
    required String treeUri,
    required String filePrefix,
    required int retention,
  }) async {
    await _channel.invokeMethod<dynamic>(
      'pruneAutoBackupsInTree',
      <String, dynamic>{
        'treeUri': treeUri,
        'filePrefix': filePrefix,
        'retention': retention,
      },
    );
  }
}
