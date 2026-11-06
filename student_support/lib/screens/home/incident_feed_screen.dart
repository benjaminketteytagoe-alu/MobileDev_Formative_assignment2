import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_colors.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/theme/app_radius.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/dicebear.dart';
import 'package:student_support/core/widgets/campus_hero.dart';
import 'package:student_support/core/widgets/category_picker.dart';
import 'package:student_support/core/widgets/dicebear_art.dart';
import 'package:student_support/core/widgets/empty_state_widget.dart';
import 'package:student_support/core/widgets/incident_list_view.dart';
import 'package:student_support/core/widgets/sector_picker.dart';
import 'package:student_support/core/widgets/sign_out_action.dart';
import 'package:student_support/core/widgets/user_avatar.dart';
import 'package:student_support/models/incident_model.dart';
import 'package:student_support/navigation/app_router.dart';
import 'package:student_support/providers/auth_provider.dart';
import 'package:student_support/providers/filter_provider.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/incident_labels.dart';

/// All campus reports under a campus hero, with search, category, sector,
/// status and urgency filters.
class IncidentFeedScreen extends ConsumerStatefulWidget {
  const IncidentFeedScreen({super.key});

  @override
  ConsumerState<IncidentFeedScreen> createState() => _IncidentFeedScreenState();
}

class _IncidentFeedScreenState extends ConsumerState<IncidentFeedScreen> {
  static const _scope = FeedScope.home;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  StateController<IncidentFilter> get _filter =>
      ref.read(incidentFilterProvider(_scope).notifier);

  void _clearFilters() {
    _searchController.clear();
    _filter.state = const IncidentFilter();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isStudent = auth != null && !auth.isStaff;
    final filter = ref.watch(incidentFilterProvider(_scope));
    final firstName = (auth?.user?.name ?? '').trim().split(' ').first;
    void openNewReport() =>
        Navigator.of(context).pushNamed(AppRouter.submitReport);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: isStudent ? 300 : 240,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: const Text(
              'CampusSupport',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: false,
            actions: const [SignOutButton()],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: CampusHero(
                greeting: firstName.isEmpty ? 'Hello' : 'Hello, $firstName',
                leading: auth?.user == null
                    ? null
                    : Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: UserAvatar(
                          userId: auth!.user!.id,
                          name: auth.user!.name,
                          size: 44,
                        ),
                      ),
                message: isStudent
                    ? 'Spotted something broken on campus? Report it in '
                          'seconds and track the fix.'
                    : 'Here is what students are reporting across campus.',
                actionLabel: isStudent ? 'Report an issue' : null,
                onAction: isStudent ? openNewReport : null,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearch(filter),
                _sectionLabel('Categories'),
                CategoryPicker(
                  selected: filter.category,
                  showAll: true,
                  tileWidth: 112,
                  tileHeight: 80,
                  sidePadding: AppSpacing.md,
                  onChanged: (value) =>
                      _filter.state = filter.copyWith(category: value),
                ),
                _sectionLabel('Location'),
                SectorPicker(
                  selected: filter.sector,
                  showAll: true,
                  sidePadding: AppSpacing.md,
                  onChanged: (value) =>
                      _filter.state = filter.copyWith(sector: value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStatusChips(filter),
                _buildUrgencyChips(filter),
              ],
            ),
          ),
        ],
        body: IncidentListView(
          incidents: ref.watch(incidentsProvider(_scope)),
          onRetry: () => ref.invalidate(incidentsProvider(_scope)),
          emptyState: filter.isActive
              ? EmptyStateWidget(
                  icon: Icons.filter_alt_off_outlined,
                  illustration: const DiceBearMascot(DiceBear.mascotSearch),
                  title: 'No matching reports',
                  message: 'Try a different search or clear the filters.',
                  actionLabel: 'Clear filters',
                  onAction: _clearFilters,
                )
              : EmptyStateWidget(
                  icon: Icons.inbox_outlined,
                  illustration: const DiceBearMascot(DiceBear.mascotEmpty),
                  title: 'No reports yet',
                  message: isStudent
                      ? 'Be the first to report a campus issue.'
                      : 'Reports submitted by students will appear here.',
                  actionLabel: isStudent ? 'Submit Report' : null,
                  onAction: isStudent ? openNewReport : null,
                ),
        ),
      ),
      floatingActionButton: isStudent
          ? FloatingActionButton(
              tooltip: 'New report',
              onPressed: openNewReport,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: context.text.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSearch(IncidentFilter filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : context.palette.border;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search reports, rooms, people...',
          hintStyle: context.text.caption,
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: context.palette.textHint,
          ),
          suffixIcon: filter.search.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _filter.state = filter.copyWith(search: '');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : context.palette.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          isDense: true,
        ),
        onChanged: (value) =>
            _filter.state = _filter.state.copyWith(search: value),
      ),
    );
  }

  Widget _buildStatusChips(IncidentFilter filter) {
    final options = <String>['', ...IncidentModel.statuses];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final status = options[index];
          final selected = filter.status == status;
          final color = status.isEmpty
              ? context.palette.accent
              : IncidentLabels.statusColor(status);
          return ChoiceChip(
            label: Text(status.isEmpty ? 'All' : IncidentLabels.status(status)),
            selected: selected,
            showCheckmark: false,
            selectedColor: color.withValues(alpha: 0.15),
            side: BorderSide(color: selected ? color : context.palette.border),
            labelStyle: context.text.caption.copyWith(
              color: selected ? color : context.palette.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            onSelected: (_) => _filter.state = filter.copyWith(status: status),
          );
        },
      ),
    );
  }

  Widget _buildUrgencyChips(IncidentFilter filter) {
    final options = <String>['', ...IncidentModel.urgencies];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final urgency = options[index];
          final selected = filter.urgency == urgency;
          final color = urgency.isEmpty
              ? context.palette.accent
              : IncidentLabels.urgencyColor(urgency);
          return ChoiceChip(
            label: Text(
              urgency.isEmpty ? 'All' : IncidentLabels.urgency(urgency),
            ),
            selected: selected,
            showCheckmark: false,
            selectedColor: color.withValues(alpha: 0.15),
            side: BorderSide(color: selected ? color : context.palette.border),
            labelStyle: context.text.caption.copyWith(
              color: selected ? color : context.palette.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            onSelected: (_) =>
                _filter.state = filter.copyWith(urgency: urgency),
          );
        },
      ),
    );
  }
}
