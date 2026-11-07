import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_shadows.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/widgets/custom_app_bar.dart';
import 'package:student_support/core/widgets/premium_button.dart';
import 'package:student_support/core/widgets/sign_out_action.dart';
import 'package:student_support/core/widgets/user_avatar.dart';
import 'package:student_support/models/notification_model.dart';
import 'package:student_support/models/user_model.dart';
import 'package:student_support/navigation/app_router.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/incident_labels.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final user = authState?.user;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile', showSignOut: true),
      body: Container(
        decoration: BoxDecoration(gradient: context.palette.pageGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.softShadow,
                  ),
                  child: UserAvatar(
                    userId: user?.id ?? '',
                    name: user?.name ?? '',
                    size: 104,
                    animated: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Name
                Text(
                  user?.name ?? 'Loading...',
                  style: context.text.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Email
                Text(
                  user?.email ?? '',
                  style: context.text.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Role badge
                if (user != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.role == UserRole.staff
                              ? Icons.badge_outlined
                              : Icons.school_outlined,
                          size: 18,
                          color: context.palette.accent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          user.role == UserRole.staff ? 'Staff' : 'Student',
                          style: context.text.caption.copyWith(
                            color: context.palette.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),

                // Profile info cards
                _buildInfoCard('Email', user?.email ?? 'N/A'),
                const SizedBox(height: AppSpacing.md),
                _buildInfoCard(
                  'Reports submitted',
                  user?.reportsSubmitted.toString() ?? '0',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildInfoCard(
                  'Member since',
                  user != null
                      ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                      : 'N/A',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Sign out sits above the notifications so it is always
                // visible without scrolling past the list.
                PremiumButton(
                  label: 'Sign Out',
                  onTap: () => confirmAndSignOut(context, ref),
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryLight, AppColors.secondary],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Notifications section
                _NotificationsSection(),
                const SizedBox(height: AppSpacing.lg),

                // Includes the DiceBear and Bootstrap Icons notices.
                TextButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'CampusSupport',
                    applicationLegalese:
                        'Avatars and icons by DiceBear (dicebear.com)',
                  ),
                  child: Text(
                    'Open-source licenses',
                    style: context.text.caption.copyWith(
                      color: context.palette.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: context.palette.textHint),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: context.text.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Notifications', style: context.text.title),
            TextButton(
              onPressed: () {
                ref.read(incidentControllerProvider).markAllNotificationsRead();
              },
              child: Text(
                'Mark all read',
                style: context.text.caption.copyWith(
                  color: context.palette.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Text(
                'No notifications yet.',
                style: context.text.body.copyWith(
                  color: context.palette.textHint,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length.clamp(0, 10),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () {
                    ref
                        .read(incidentControllerProvider)
                        .markNotificationRead(notification.id);
                    final incidentId = notification.incidentId;
                    if (incidentId != null) {
                      Navigator.of(context).pushNamed(
                        AppRouter.incidentDetail,
                        arguments: incidentId,
                      );
                    }
                  },
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Text(
            'Could not load notifications.',
            style: context.text.body.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.read
              ? Theme.of(context).cardColor
              : context.palette.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: notification.read
                ? context.palette.border
                : context.palette.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 20,
              color: notification.read
                  ? context.palette.textHint
                  : context.palette.accent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: context.text.body.copyWith(
                      fontWeight: notification.read ? null : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    IncidentLabels.relativeDate(notification.at),
                    style: context.text.caption,
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.palette.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
