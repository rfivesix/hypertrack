import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/feedback_report/application/feedback_report_actions.dart';

void main() {
  group('FeedbackReportActions.buildFeedbackEmailUri', () {
    test('builds mailto URI with expected recipient, subject, and body', () {
      final uri = FeedbackReportActions.buildFeedbackEmailUri(
        reportText: 'Train Libre Feedback Report\n- item: value',
        subject: 'Train Libre feedback report',
        userNote: 'Please check recommendation drift & apply state.',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'feedback@schotte.me');
      expect(uri.queryParameters['subject'], 'Train Libre feedback report');

      final body = uri.queryParameters['body'];
      expect(body, isNotNull);
      expect(body!, contains('Train Libre feedback report'));
      expect(body, contains('User note:'));
      expect(
          body, contains('Please check recommendation drift & apply state.'));
      expect(body, contains('Report:'));
      expect(body, contains('Train Libre Feedback Report'));
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
