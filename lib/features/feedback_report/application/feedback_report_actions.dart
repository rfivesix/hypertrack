import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ClipboardWriter = Future<void> Function(String text);
typedef TemporaryDirectoryProvider = Future<Directory> Function();
typedef ShareInvoker = Future<ShareResult> Function(ShareParams params);
typedef UrlOpener = Future<bool> Function(Uri uri);
typedef ActionNowProvider = DateTime Function();

class FeedbackReportActions {
  final ClipboardWriter _clipboardWriter;
  final TemporaryDirectoryProvider _temporaryDirectoryProvider;
  final ShareInvoker _shareInvoker;
  final UrlOpener _urlOpener;
  final ActionNowProvider _nowProvider;

  FeedbackReportActions({
    ClipboardWriter? clipboardWriter,
    TemporaryDirectoryProvider? temporaryDirectoryProvider,
    ShareInvoker? shareInvoker,
    UrlOpener? urlOpener,
    ActionNowProvider? nowProvider,
  })  : _clipboardWriter = clipboardWriter ?? _defaultClipboardWriter,
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory,
        _shareInvoker = shareInvoker ?? _defaultShareInvoker,
        _urlOpener = urlOpener ?? _defaultUrlOpener,
        _nowProvider = nowProvider ?? DateTime.now;

  Future<void> copyReport(String reportText) async {
    await _clipboardWriter(reportText);
  }

  Future<File> saveReportToTemporaryFile({
    required String reportText,
  }) async {
    final tempDir = await _temporaryDirectoryProvider();
    final now = _nowProvider();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    final file = File(
      p.join(tempDir.path, 'hypertrack_feedback_report_$stamp.txt'),
    );
    await file.writeAsString(reportText, flush: true);
    return file;
  }

  Future<ShareResultStatus> shareReport({
    required String reportText,
    String? existingFilePath,
    String? subject,
  }) async {
    final file = existingFilePath == null || existingFilePath.trim().isEmpty
        ? await saveReportToTemporaryFile(reportText: reportText)
        : File(existingFilePath.trim());

    final result = await _shareInvoker(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain')],
        subject: subject,
        sharePositionOrigin: _sharePositionOrigin(),
      ),
    );
    return result.status;
  }

  Future<bool> openFeedbackEmailDraft({
    required String reportText,
    required String subject,
    String? userNote,
    String recipient = 'feedback@schotte.me',
  }) {
    final uri = buildFeedbackEmailUri(
      reportText: reportText,
      subject: subject,
      userNote: userNote,
      recipient: recipient,
    );
    return _urlOpener(uri);
  }

  static Uri buildFeedbackEmailUri({
    required String reportText,
    required String subject,
    String? userNote,
    String recipient = 'feedback@schotte.me',
  }) {
    final trimmedNote = userNote?.trim() ?? '';
    final bodyBuffer = StringBuffer()
      ..writeln('Hypertrack feedback report')
      ..writeln();

    if (trimmedNote.isNotEmpty) {
      bodyBuffer
        ..writeln('User note:')
        ..writeln(trimmedNote)
        ..writeln();
    }

    bodyBuffer
      ..writeln('Report:')
      ..writeln(reportText);

    return Uri(
      scheme: 'mailto',
      path: recipient,
      queryParameters: {
        'subject': subject,
        'body': bodyBuffer.toString(),
      },
    );
  }

  static Future<void> _defaultClipboardWriter(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }

  static Future<ShareResult> _defaultShareInvoker(ShareParams params) {
    return SharePlus.instance.share(params);
  }

  static Future<bool> _defaultUrlOpener(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Rect _sharePositionOrigin() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }

    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return Rect.fromLTWH(
      0,
      0,
      math.max(1, logicalSize.width),
      math.max(1, logicalSize.height),
    );
  }
}
