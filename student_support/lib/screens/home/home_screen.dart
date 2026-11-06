import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/widgets/custom_bottom_nav.dart';
import 'package:student_support/core/widgets/offline_banner.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/screens/home/incident_feed_screen.dart';
import 'package:student_support/screens/profile/profile_screen.dart';
import 'package:student_support/screens/report/my_reports_screen.dart';
import 'package:student_support/screens/staff/staff_dashboard_screen.dart';

/// Main shell after sign-in. The bottom bar switches tabs in place instead of
/// pushing new screens, so the back button behaves as expected.
///
/// Students: All Reports, My Reports, Profile.
/// Staff:    All Reports, Dashboard, Profile.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final hasStaffRole =
        authState?.isStaff == true || authState?.needsStaffVerification == true;

    final tabs = <Widget>[
      const IncidentFeedScreen(),
      hasStaffRole ? const StaffDashboardScreen() : const MyReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              // Hidden tabs stay mounted, so their Hero widgets are disabled to
              // avoid duplicate tags during page transitions.
              for (var i = 0; i < tabs.length; i++)
                HeroMode(enabled: i == _selectedIndex, child: tabs[i]),
            ],
          ),
          const SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: OfflineBanner(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        isStaff: hasStaffRole,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
