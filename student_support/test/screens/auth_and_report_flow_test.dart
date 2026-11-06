import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/models/report_draft_model.dart';
import 'package:student_support/models/user_model.dart';
import 'package:student_support/navigation/app_router.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/screens/auth/login_screen.dart';
import 'package:student_support/screens/auth/register_screen.dart';
import 'package:student_support/screens/report/submit_report_screen.dart';
import 'package:student_support/services/incident_service.dart';

/// Records draft calls. Anything else the screen might call fails loudly.
class _FakeIncidentService implements IncidentService {
  ReportDraftModel? stored;
  bool deleted = false;

  @override
  Future<ReportDraftModel?> getDraft(String uid) async => stored;

  @override
  Future<void> saveDraft(String uid, ReportDraftModel draft) async =>
      stored = draft;

  @override
  Future<void> deleteDraft(String uid) async {
    deleted = true;
    stored = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _student = AuthState(
  status: AuthStatus.authenticated,
  user: UserModel(id: 'u1', name: 'Ama Mensah', email: 'a@alustudent.com'),
);

void main() {
  group('auth screens', () {
    Widget app(Widget home) => ProviderScope(
      child: MaterialApp(home: home, onGenerateRoute: AppRouter.onGenerateRoute),
    );

    testWidgets('login offers Google and email/password sign-in', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LoginScreen()));
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('or sign in with email'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('forgot password carries the typed email over', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LoginScreen()));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ALU email'),
        'ama@alustudent.com',
      );
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('ama@alustudent.com'), findsOneWidget);
    });

    testWidgets('sign up offers Google and shows the detected role', (
      tester,
    ) async {
      await tester.pumpWidget(app(const RegisterScreen()));
      expect(find.text('Sign up with Google'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ALU email'),
        'kofi@alueducation.com',
      );
      await tester.pump();
      expect(find.textContaining('Staff account'), findsOneWidget);
    });

    testWidgets('sign up rejects non-ALU email addresses', (tester) async {
      await tester.pumpWidget(app(const RegisterScreen()));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ALU email'),
        'someone@gmail.com',
      );
      await tester.ensureVisible(find.text('Create Account'));
      await tester.tap(find.text('Create Account'));
      await tester.pump();
      expect(
        find.text('Use your @alustudent.com or @alueducation.com email'),
        findsOneWidget,
      );
    });
  });

  group('new report', () {
    late _FakeIncidentService service;

    Future<void> openForm(WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_student)),
            incidentServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('Feed')),
          ),
        ),
      );
      await tester.pump();
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const SubmitReportScreen()),
      );
      await tester.pumpAndSettle();
    }

    setUp(() => service = _FakeIncidentService());

    testWidgets('has Submit and Cancel buttons', (tester) async {
      await openForm(tester);
      expect(find.text('Submit Report'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel on an empty form just closes it', (tester) async {
      await openForm(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Feed'), findsOneWidget);
      expect(service.stored, isNull);
    });

    testWidgets('Cancel with input offers to save a draft and saves it', (
      tester,
    ) async {
      await openForm(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Leaking tap',
      );
      // The sector cards scroll sideways; bring this one into view first.
      await tester.ensureVisible(find.text('Leadership Centre'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leadership Centre'));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Save this report as a draft?'), findsOneWidget);

      await tester.tap(find.text('Save draft'));
      await tester.pumpAndSettle();
      expect(find.text('Feed'), findsOneWidget);
      expect(service.stored?.title, 'Leaking tap');
      expect(service.stored?.sector, 'leadership_centre');
    });

    testWidgets('Discard deletes the draft', (tester) async {
      await openForm(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Broken chair',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Feed'), findsOneWidget);
      expect(service.deleted, isTrue);
    });

    testWidgets('a saved draft is restored when the form opens', (
      tester,
    ) async {
      service.stored = ReportDraftModel(
        title: 'Flickering lights',
        sector: 'collaboration_street',
        locationDetail: 'Near the stairs',
      );
      await openForm(tester);
      expect(find.text('Flickering lights'), findsOneWidget);
      expect(find.text('Near the stairs'), findsOneWidget);
      expect(find.text('Your saved draft was restored.'), findsOneWidget);
    });

    testWidgets('submitting without a sector asks for one', (tester) async {
      await openForm(tester);
      await tester.tap(find.text('Submit Report'));
      await tester.pump();
      expect(find.text('Choose the campus sector'), findsOneWidget);
    });
  });
}
