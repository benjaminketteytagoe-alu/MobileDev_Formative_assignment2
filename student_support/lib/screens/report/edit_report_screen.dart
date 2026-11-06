import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_support/core/theme/app_spacing.dart';
import 'package:student_support/core/theme/app_palette.dart';
import 'package:student_support/core/widgets/category_picker.dart';
import 'package:student_support/core/widgets/custom_app_bar.dart';
import 'package:student_support/core/widgets/empty_state_widget.dart';
import 'package:student_support/core/widgets/error_banner.dart';
import 'package:student_support/core/widgets/form_action_bar.dart';
import 'package:student_support/core/widgets/premium_text_field.dart';
import 'package:student_support/core/widgets/sector_picker.dart';
import 'package:student_support/core/widgets/urgency_selector.dart';
import 'package:student_support/providers/incident_provider.dart';
import 'package:student_support/utils/error_messages.dart';
import 'package:student_support/utils/incident_labels.dart';
import 'package:student_support/utils/validators.dart';

class EditReportScreen extends ConsumerStatefulWidget {
  final String incidentId;

  const EditReportScreen({super.key, required this.incidentId});

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  // Created up front so dispose() is safe even if loading fails.
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'facility';
  String _selectedSector = '';
  String _selectedUrgency = 'medium';
  bool _isLoading = false;
  bool _loadingData = true;
  bool _notFound = false;
  bool _dirty = false;
  bool _leaving = false;
  String? _error;
  String? _sectorError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final incident = await ref
          .read(incidentServiceProvider)
          .getIncidentById(widget.incidentId)
          .first;
      if (!mounted) return;
      if (incident == null) {
        setState(() {
          _loadingData = false;
          _notFound = true;
        });
        return;
      }

      _titleController.text = incident.title;
      _descriptionController.text = incident.description;
      _locationController.text = IncidentLabels.locationDetail(
        incident.location,
        incident.sector,
      );
      setState(() {
        _selectedCategory = incident.category;
        _selectedSector = incident.sector;
        _selectedUrgency = incident.urgency;
        _loadingData = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingData = false;
          _error = describeError(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _markDirty(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  Future<void> _save() async {
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

    try {
      await ref
          .read(incidentControllerProvider)
          .editIncident(
            incidentId: widget.incidentId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            sector: _selectedSector,
            location: IncidentLabels.composeLocation(
              _selectedSector,
              _locationController.text,
            ),
            urgency: _selectedUrgency,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully.')),
        );
        _leaving = true;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    if (_isLoading) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard your changes?'),
          content: const Text('The report stays as it was before you edited it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    _leaving = true;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !_loadingData && !_notFound;
    return PopScope(
      canPop: _leaving || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Edit Report',
          showBack: true,
          onBack: _cancel,
        ),
        bottomNavigationBar: canEdit
            ? FormActionBar(
                primaryLabel: 'Save Changes',
                onPrimary: _save,
                onCancel: _cancel,
                isLoading: _isLoading,
              )
            : null,
        body: SafeArea(bottom: false, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingData) return const Center(child: CircularProgressIndicator());
    if (_notFound) {
      return const EmptyStateWidget(
        icon: Icons.search_off_outlined,
        title: 'Report not found',
        message: 'It may have been deleted.',
      );
    }

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: child,
    );
    Widget label(String text) => padded(
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: context.text.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Form(
        key: _formKey,
        onChanged: () => _markDirty(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            padded(
              PremiumTextField(
                controller: _titleController,
                hintText: 'Report title',
                labelText: 'Title',
                prefixIcon: const Icon(Icons.title),
                validator: (v) =>
                    Validators.required(v, 'Title') ??
                    Validators.maxLength(v, 120, 'Title'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            label('Category'),
            CategoryPicker(
              selected: _selectedCategory,
              sidePadding: AppSpacing.lg,
              onChanged: (value) => _markDirty(() => _selectedCategory = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            label('Location'),
            SectorPicker(
              selected: _selectedSector,
              sidePadding: AppSpacing.lg,
              errorText: _sectorError,
              onChanged: (value) => _markDirty(() {
                _selectedSector = value;
                _sectorError = null;
              }),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            padded(
              PremiumTextField(
                controller: _locationController,
                hintText: 'Room, floor or spot (optional)',
                labelText: 'Room or area',
                prefixIcon: const Icon(Icons.meeting_room_outlined),
                validator: (v) => Validators.maxLength(v, 150, 'Room or area'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            padded(
              PremiumTextField(
                controller: _descriptionController,
                hintText: 'Describe the issue in detail...',
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description_outlined),
                maxLines: 4,
                validator: (v) =>
                    Validators.minLength(v, 10, 'Description') ??
                    Validators.maxLength(v, 2000, 'Description'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            padded(
              UrgencySelector(
                selected: _selectedUrgency,
                onChanged: (value) =>
                    _markDirty(() => _selectedUrgency = value),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              padded(ErrorBanner(message: _error!)),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
