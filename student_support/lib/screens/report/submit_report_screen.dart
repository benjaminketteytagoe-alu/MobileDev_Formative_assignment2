import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/widgets/category_picker.dart';
import 'package:student_support/core/widgets/custom_app_bar.dart';
import 'package:student_support/core/widgets/error_banner.dart';
import 'package:student_support/core/widgets/form_action_bar.dart';
import 'package:student_support/core/widgets/photo_attachments.dart';
import 'package:student_support/core/widgets/premium_text_field.dart';
import 'package:student_support/core/widgets/sector_picker.dart';
import 'package:student_support/core/widgets/urgency_selector.dart';
import 'package:student_support/models/report_draft_model.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/error_messages.dart';
import 'package:student_support/utils/incident_labels.dart';
import 'package:student_support/utils/validators.dart';

/// What the user chose when leaving a report they had started.
enum _LeaveChoice { saveDraft, discard, keepEditing }

class SubmitReportScreen extends ConsumerStatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  ConsumerState<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends ConsumerState<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'facility';
  String _selectedSector = '';
  String _selectedUrgency = 'medium';
  List<String> _imagePaths = [];
  bool _anonymous = false;

  bool _isLoading = false;
  String? _error;
  String? _sectorError;

  /// Set once the user has decided to leave, so the pop is not intercepted
  /// a second time.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  ReportDraftModel get _currentDraft => ReportDraftModel(
    title: _titleController.text.trim(),
    description: _descriptionController.text.trim(),
    category: _selectedCategory,
    sector: _selectedSector,
    locationDetail: _locationController.text.trim(),
    anonymous: _anonymous,
    urgency: _selectedUrgency,
    localImagePaths: _imagePaths,
  );

  bool get _hasInput => !_currentDraft.isEmpty;

  Future<void> _restoreDraft() async {
    final draft = await ref.read(incidentControllerProvider).loadDraft();
    // Do not overwrite anything typed while the draft was loading.
    if (draft == null || !mounted || _hasInput) return;

    // Photos live on the phone; skip any that were deleted since, or that
    // were taken on another device.
    final photos = draft.localImagePaths
        .where((path) => File(path).existsSync())
        .take(maxPhotosPerReport)
        .toList();

    setState(() {
      _titleController.text = draft.title;
      _descriptionController.text = draft.description;
      _locationController.text = draft.locationDetail;
      _selectedCategory = draft.category;
      _selectedSector = draft.sector;
      _selectedUrgency = draft.urgency;
      _anonymous = draft.anonymous;
      _imagePaths = photos;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your saved draft was restored.'),
        action: SnackBarAction(label: 'Start over', onPressed: _startOver),
      ),
    );
  }

  void _startOver() {
    _formKey.currentState?.reset();
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _selectedCategory = 'facility';
      _selectedSector = '';
      _selectedUrgency = 'medium';
      _imagePaths = [];
      _error = null;
      _sectorError = null;
      _anonymous = false;
    });
    ref.read(incidentControllerProvider).clearDraft();
  }

  Future<void> _submitReport() async {
    final formValid = _formKey.currentState!.validate();
    setState(
      () => _sectorError = _selectedSector.isEmpty
          ? 'Choose the campus sector'
          : null,
    );
    if (!formValid || _sectorError != null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(incidentControllerProvider)
          .submit(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            sector: _selectedSector,
            location: IncidentLabels.composeLocation(
              _selectedSector,
              _locationController.text,
            ),
            urgency: _selectedUrgency,
            imagePaths: _imagePaths,
            anonymous: _anonymous,
          );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Track it under My Reports.'),
        ),
      );
      _leaving = true;
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Cancel button, back button and system back all end up here.
  Future<void> _cancel() async {
    if (_isLoading) return;
    if (!_hasInput) {
      _leave();
      return;
    }

    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.save_outlined),
        title: const Text('Save this report as a draft?'),
        content: const Text(
          'Your draft is saved to your account. Next time you tap New Report, '
          'you can pick up where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LeaveChoice.discard),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_LeaveChoice.keepEditing),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_LeaveChoice.saveDraft),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    final controller = ref.read(incidentControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    switch (choice) {
      case _LeaveChoice.saveDraft:
        try {
          await controller.saveDraft(_currentDraft);
          messenger.showSnackBar(const SnackBar(content: Text('Draft saved.')));
          _leave();
        } catch (e) {
          if (mounted) setState(() => _error = describeError(e));
        }
      case _LeaveChoice.discard:
        await controller.clearDraft();
        _leave();
      case _LeaveChoice.keepEditing:
      case null:
        break;
    }
  }

  void _leave() {
    _leaving = true;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _leaving || !_hasInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'New Report',
          showBack: true,
          onBack: _cancel,
        ),
        bottomNavigationBar: FormActionBar(
          primaryLabel: 'Submit Report',
          onPrimary: _submitReport,
          onCancel: _cancel,
          isLoading: _isLoading,
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Form(
              key: _formKey,
              // Rebuild so the Cancel/back behaviour follows what is typed.
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _padded(
                    PremiumTextField(
                      controller: _titleController,
                      hintText: 'e.g. Leaking tap in the washroom',
                      labelText: 'Title',
                      prefixIcon: const Icon(Icons.title),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.required(v, 'Title') ??
                          Validators.maxLength(v, 120, 'Title'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _SectionLabel('Category'),
                  CategoryPicker(
                    selected: _selectedCategory,
                    sidePadding: AppSpacing.lg,
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _SectionLabel('Location'),
                  SectorPicker(
                    selected: _selectedSector,
                    sidePadding: AppSpacing.lg,
                    errorText: _sectorError,
                    onChanged: (value) => setState(() {
                      _selectedSector = value;
                      _sectorError = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  _padded(
                    PremiumTextField(
                      controller: _locationController,
                      hintText: 'Room, floor or spot (optional)',
                      labelText: 'Room or area',
                      prefixIcon: const Icon(Icons.meeting_room_outlined),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          Validators.maxLength(v, 150, 'Room or area'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _padded(
                    PremiumTextField(
                      controller: _descriptionController,
                      hintText: 'What is wrong, since when, and who is affected?',
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      maxLines: 4,
                      validator: (v) =>
                          Validators.minLength(v, 10, 'Description') ??
                          Validators.maxLength(v, 2000, 'Description'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _padded(
                    UrgencySelector(
                      selected: _selectedUrgency,
                      onChanged: (value) =>
                          setState(() => _selectedUrgency = value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _SectionLabel(
                    'Photos (optional, up to $maxPhotosPerReport)',
                  ),
                  _padded(
                    PhotoAttachments(
                      paths: _imagePaths,
                      maxCount: maxPhotosPerReport,
                      onChanged: (paths) =>
                          setState(() => _imagePaths = paths),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    title: const Text('Report anonymously'),
                    subtitle: const Text(
                      'Your name and avatar stay hidden in the app. Your '
                      'account stays linked so staff can act on misuse.',
                    ),
                    value: _anonymous,
                    onChanged: (value) => setState(() => _anonymous = value),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _padded(ErrorBanner(message: _error!)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: context.text.caption.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
