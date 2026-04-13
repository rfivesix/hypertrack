import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/features/feedback_report/application/feedback_report_actions.dart';

void main() {
  group('FeedbackReportActions.buildFeedbackEmailUri', () {
    test('builds mailto URI with expected recipient, subject, and body', () {
      final uri = FeedbackReportActions.buildFeedbackEmailUri(
        reportText: 'Hypertrack Feedback Report\n- item: value',
        subject: 'Hypertrack feedback report',
        userNote: 'Please check recommendation drift & apply state.',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'feedback@schotte.me');
      expect(uri.queryParameters['subject'], 'Hypertrack feedback report');

      final body = uri.queryParameters['body'];
      expect(body, isNotNull);
      expect(body!, contains('Hypertrack feedback report'));
      expect(body, contains('User note:'));
      expect(
          body, contains('Please check recommendation drift & apply state.'));
      expect(body, contains('Report:'));
      expect(body, contains('Hypertrack Feedback Report'));
    });

    test('omits user-note block when no note is provided', () {
      final uri = FeedbackReportActions.buildFeedbackEmailUri(
        reportText: 'Report content',
        subject: 'Subject',
        userNote: '   ',
      );

      final body = uri.queryParameters['body'];
      expect(body, isNotNull);
      expect(body!, isNot(contains('User note:')));
      expect(body, contains('Report:'));
      expect(body, contains('Report content'));
    });
  });
}
