import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/core/widgets/user_avatar.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/models/user_model.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/screens/detail/incident_detail_screen.dart';
import 'package:student_support/screens/staff/staff_dashboard_screen.dart';

AuthState _signedIn(UserRole role) => AuthState(
  status: AuthStatus.authenticated,
  user: UserModel(id: 'u1', name: 'Test', email: 'test@x.com', role: role),
);

Widget _app(Widget child, AuthState auth, {List<Override> extra = const []}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(auth)),
      ...extra,
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  final incident = IncidentModel(
    id: 'i1',
    title: 'Broken light',
    description: 'The corridor light has been off for two days',
    category: 'electricity',
    location: 'Block B',
    reporterId: 'u2',
    reporterName: 'Student',
  );
  // The detail screen also reads votes and history. Stub them so the test
  // never reaches Firebase.
  final detailOverrides = <Override>[
    incidentByIdProvider.overrideWith((ref, id) => Stream.value(incident)),
    voteStatusProvider.overrideWith((ref, id) => Stream.value(false)),
    historyProvider.overrideWith((ref, id) => Stream.value(const [])),
    hasFlaggedProvider.overrideWith((ref, id) => Stream.value(false)),
    flagCountProvider.overrideWith((ref, id) => Stream.value(0)),
  ];

  testWidgets('students cannot open the staff dashboard', (tester) async {
    await tester.pumpWidget(
      _app(const StaffDashboardScreen(), _signedIn(UserRole.student)),
    );
    await tester.pump();
    expect(find.text('Staff access only'), findsOneWidget);
  });

  testWidgets('an anonymous report hides the name and avatar', (tester) async {
    final anonymous = incident.copyWith(
      anonymous: true,
      reporterName: IncidentModel.anonymousName,
    );
    await tester.pumpWidget(
      _app(
        const IncidentDetailScreen(incidentId: 'i1'),
        _signedIn(UserRole.student),
        extra: [
          ...detailOverrides,
          incidentByIdProvider.overrideWith(
            (ref, id) => Stream.value(anonymous),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(IncidentModel.anonymousName), findsOneWidget);
    expect(find.byType(UserAvatar), findsNothing);
  });

  testWidgets('students can flag a report', (tester) async {
    await tester.pumpWidget(
      _app(
        const IncidentDetailScreen(incidentId: 'i1'),
        _signedIn(UserRole.student),
        extra: detailOverrides,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Flag this report'), findsOneWidget);
    expect(find.textContaining('Flagged as false'), findsNothing);
  });

  testWidgets('staff see the flag count instead of the flag button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const IncidentDetailScreen(incidentId: 'i1'),
        _signedIn(UserRole.staff),
        extra: [
          ...detailOverrides,
          flagCountProvider.overrideWith((ref, id) => Stream.value(2)),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Flag this report'), findsNothing);
    expect(find.textContaining('by 2 people'), findsOneWidget);
  });

  testWidgets('students do not see status controls on a report', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const IncidentDetailScreen(incidentId: 'i1'),
        _signedIn(UserRole.student),
        extra: detailOverrides,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Broken light'), findsOneWidget);
    expect(find.text('Update Status'), findsNothing);
  });

  testWidgets('staff see status controls on a report', (tester) async {
    await tester.pumpWidget(
      _app(
        const IncidentDetailScreen(incidentId: 'i1'),
        _signedIn(UserRole.staff),
        extra: detailOverrides,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Update Status'), findsOneWidget);
    expect(find.text('Assign to me'), findsOneWidget);
  });

  testWidgets('rejecting a report requires a reason', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const IncidentDetailScreen(incidentId: 'i1'),
        _signedIn(UserRole.staff),
        extra: detailOverrides,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Rejected').last);
    await tester.pumpAndSettle();
    expect(find.text('Reject this report?'), findsOneWidget);

    TextButton confirm() => tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Reject report'),
    );
    expect(confirm().onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      'Duplicate of an open report',
    );
    await tester.pump();
    expect(confirm().onPressed, isNotNull);
  });

  testWidgets('a rejected report does not show the resolved step', (
    tester,
  ) async {
    final rejected = incident.copyWith(status: 'rejected');
    await tester.pumpWidget(
      _app(
        const IncidentDetailScreen(incidentId: 'i1'),
        _signedIn(UserRole.student),
        extra: [
          ...detailOverrides.skip(1),
          incidentByIdProvider.overrideWith(
            (ref, id) => Stream.value(rejected),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resolved'), findsNothing);
    expect(find.text('Rejected'), findsWidgets);
  });

  testWidgets('main tabs offer sign out with a confirmation', (tester) async {
    await tester.pumpWidget(
      _app(const StaffDashboardScreen(), _signedIn(UserRole.student)),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsNothing);
  });
}
