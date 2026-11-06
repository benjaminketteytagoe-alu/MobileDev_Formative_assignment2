import 'package:flutter/material.dart';

import '../core/widgets/custom_transition.dart';
import '../core/widgets/empty_state_widget.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/detail/incident_detail_screen.dart';
import '../screens/report/edit_report_screen.dart';
import '../screens/report/submit_report_screen.dart';

/// Named routes for screens that are pushed on top of the main shell.
/// The login screen and the tabbed home screen are chosen by the auth gate
/// in main.dart, not by a route.
class AppRouter {
  AppRouter._();

  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String submitReport = '/submit-report';
  static const String editReport = '/edit-report';

  /// Pass the incident id as the route argument.
  static const String incidentDetail = '/incident';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return customTransition(const RegisterScreen(), settings: settings);
      case forgotPassword:
        final email = settings.arguments;
        return customTransition(
          ForgotPasswordScreen(initialEmail: email is String ? email : null),
          settings: settings,
        );
      case submitReport:
        return customTransition(const SubmitReportScreen(), settings: settings);
      case editReport:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['incidentId'] is String) {
          return customTransition(
            EditReportScreen(incidentId: args['incidentId'] as String),
            settings: settings,
          );
        }
        return _notFound(settings);
      case incidentDetail:
        final id = settings.arguments;
        if (id is String && id.isNotEmpty) {
          return customTransition(
            IncidentDetailScreen(incidentId: id),
            settings: settings,
          );
        }
        return _notFound(settings);
      default:
        return _notFound(settings);
    }
  }

  static Route<dynamic> _notFound(RouteSettings settings) {
    return customTransition(
      const Scaffold(
        body: EmptyStateWidget(
          icon: Icons.help_outline,
          title: 'Page not found',
          message: 'This page does not exist.',
        ),
      ),
      settings: settings,
    );
  }
}
