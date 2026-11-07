import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/core/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders with icon, title, and message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'Empty',
              message: 'No items found',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'Empty',
              message: 'No items found',
              actionLabel: 'Add Item',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('does not render action button when not provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'Empty',
              message: 'No items found',
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsNothing);
    });
  });
}
