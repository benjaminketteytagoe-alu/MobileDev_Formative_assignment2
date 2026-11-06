import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/dicebear.dart';
import 'package:student_support/core/widgets/custom_app_bar.dart';
import 'package:student_support/core/widgets/dicebear_art.dart';
import 'package:student_support/core/widgets/empty_state_widget.dart';
import 'package:student_support/core/widgets/incident_list_view.dart';
import 'package:student_support/navigation/app_router.dart';
import 'package:student_support/providers/incident_provider.dart';

/// Reports submitted by the signed-in student, so they can follow each one
/// from Pending to Resolved.
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'My Reports', showSignOut: true),
      body: IncidentListView(
        incidents: ref.watch(myIncidentsProvider),
        onRetry: () => ref.invalidate(myIncidentsProvider),
        emptyState: EmptyStateWidget(
          icon: Icons.assignment_outlined,
          illustration: const DiceBearMascot(DiceBear.mascotEmpty),
          title: 'No reports yet',
          message: 'Reports you submit appear here with their current status.',
          actionLabel: 'Submit Report',
          onAction: () =>
              Navigator.of(context).pushNamed(AppRouter.submitReport),
        ),
      ),
    );
  }
}
