// lib/data/base_db_exporter.dart
import 'package:share_plus/share_plus.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'product_database_helper.dart';

/// Utility class for exporting and sharing the base database file.
class BaseDbExporter {
  /// Shares the base database file using the system's share sheet.
  ///
  /// The [subject] parameter allows overriding the default share subject.
  static Future<void> shareBaseDb({String? subject}) async {
    final path = await ProductDatabaseHelper.instance.getBaseDbPath();
    final file = XFile(
      path,
      mimeType: lookupMimeType(path) ?? 'application/octet-stream',
      name: basename(path),
    );
    await Share.shareXFiles([
      file,
    ], subject: subject ?? 'hypertrack_base_foods.db');
  }
}
