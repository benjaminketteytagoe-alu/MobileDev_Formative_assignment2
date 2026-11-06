import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_entry_model.dart';
import '../models/incident_model.dart';
import '../models/notification_model.dart';
import '../models/report_draft_model.dart';
import '../services/incident_service.dart';
import '../services/storage_service.dart';
import '../utils/error_messages.dart';
import '../utils/incident_labels.dart';
import 'auth_provider.dart';
import 'filter_provider.dart';

/// Maximum photos per report. Must match the limit in firestore.rules.
const int maxPhotosPerReport = 5;

final incidentServiceProvider = Provider<IncidentService>((ref) {
  return IncidentService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Connectivity status for offline detection.
final offlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool isOffline(List<ConnectivityResult> results) =>
      results.contains(ConnectivityResult.none);

  // The change stream alone would miss a phone that starts without a network.
  yield isOffline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(isOffline);
});

/// Firestore query for one list. Category, status and urgency are watched
/// here, so typing in the search box does not reopen the Firestore listener.
final _incidentQueryProvider = StreamProvider.autoDispose
    .family<List<IncidentModel>, FeedScope>((ref, scope) {
      final category = ref.watch(
        incidentFilterProvider(scope).select((f) => f.category),
      );
      final status = ref.watch(
        incidentFilterProvider(scope).select((f) => f.status),
      );
      final urgency = ref.watch(
        incidentFilterProvider(scope).select((f) => f.urgency),
      );
      return ref
          .watch(incidentServiceProvider)
          .getIncidentsStream(
            category: category,
            status: status,
            urgency: urgency,
          );
    });

/// The list shown on screen: the Firestore results with text search and the
/// sector filter applied. Sector is filtered here rather than in Firestore so
/// it needs no extra composite indexes.
final incidentsProvider = Provider.autoDispose
    .family<AsyncValue<List<IncidentModel>>, FeedScope>((ref, scope) {
      final search = ref.watch(
        incidentFilterProvider(scope).select((f) => f.search),
      );
      final sector = ref.watch(
        incidentFilterProvider(scope).select((f) => f.sector),
      );
      return ref
          .watch(_incidentQueryProvider(scope))
          .whenData(
            (incidents) => incidents
                .where((incident) => sector.isEmpty || incident.sector == sector)
                .where((incident) => incident.matchesQuery(search))
                .toList(),
          );
    });

/// Reports submitted by the signed-in user.
final myIncidentsProvider = StreamProvider.autoDispose<List<IncidentModel>>((
  ref,
) {
  final userId = ref.watch(
    authStateProvider.select((state) => state.valueOrNull?.user?.id),
  );
  if (userId == null || userId.isEmpty) return Stream.value(const []);
  return ref
      .watch(incidentServiceProvider)
      .getIncidentsStream(reporterId: userId);
});

final incidentByIdProvider = StreamProvider.autoDispose
    .family<IncidentModel?, String>((ref, id) {
      return ref.watch(incidentServiceProvider).getIncidentById(id);
    });

final incidentCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  status,
) {
  return ref.watch(incidentServiceProvider).getCountByStatusStream(status);
});

/// Stream of history entries for an incident.
final historyProvider = StreamProvider.autoDispose
    .family<List<HistoryEntryModel>, String>((ref, incidentId) {
      return ref.watch(incidentServiceProvider).getHistoryStream(incidentId);
    });

/// Whether the current user has voted on an incident.
final voteStatusProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  incidentId,
) {
  final uid =
      ref.watch(authStateProvider.select((s) => s.valueOrNull?.user?.id)) ?? '';
  if (uid.isEmpty) return Stream.value(false);
  return ref
      .watch(incidentServiceProvider)
      .getVoteStatus(incidentId: incidentId, uid: uid);
});

/// Stream of notifications for the current user.
/// Whether the signed-in user has flagged a report.
final hasFlaggedProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  incidentId,
) {
  final uid = ref.watch(authStateProvider).valueOrNull?.user?.id ?? '';
  if (uid.isEmpty) return Stream.value(false);
  return ref
      .watch(incidentServiceProvider)
      .hasFlagged(incidentId: incidentId, uid: uid);
});

/// How many people flagged a report. Staff only.
final flagCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  incidentId,
) {
  return ref.watch(incidentServiceProvider).getFlagCount(incidentId);
});

final notificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final userId = ref.watch(
        authStateProvider.select((state) => state.valueOrNull?.user?.id),
      );
      if (userId == null || userId.isEmpty) return Stream.value(const []);
      return ref.watch(incidentServiceProvider).getNotificationsStream(userId);
    });

final incidentControllerProvider = Provider<IncidentController>((ref) {
  return IncidentController(ref);
});

/// Write operations on incidents. Screens call these instead of talking to
/// the services directly.
class IncidentController {
  IncidentController(this._ref);

  final Ref _ref;

  Future<void> submit({
    required String title,
    required String description,
    required String category,
    required String sector,
    required String location,
    required String urgency,
    required List<String> imagePaths,
    bool anonymous = false,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull?.user;
    if (user == null || user.id.isEmpty) {
      throw const AppException('You need to be signed in to submit a report.');
    }
    if (imagePaths.length > maxPhotosPerReport) {
      throw const AppException(
        'You can attach up to $maxPhotosPerReport photos.',
      );
    }

    final storage = _ref.read(storageServiceProvider);
    final uploaded = <String>[];
    final batchId = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      final ext = StorageService.extensionOf(path);
      try {
        final url = await storage.uploadImage(
          File(path),
          'incidents/${user.id}/${batchId}_$i.$ext',
        );
        uploaded.add(url);
      } catch (e) {
        await _deleteAll(storage, uploaded);
        throw AppException(
          'Photo ${i + 1} could not be uploaded. ${describeError(e)}',
        );
      }
    }

    final incident = IncidentModel(
      title: title,
      description: description,
      category: category,
      location: location,
      sector: sector,
      urgency: urgency,
      reporterId: user.id,
      reporterName: anonymous ? IncidentModel.anonymousName : user.name,
      anonymous: anonymous,
      images: uploaded,
      searchKeywords: IncidentModel.generateSearchKeywords(title),
    );

    try {
      // Writes the report and its first history entry together.
      await _ref.read(incidentServiceProvider).createIncident(incident);
    } catch (e) {
      await _deleteAll(storage, uploaded);
      rethrow;
    }

    // The report is saved at this point, so a failed counter update or
    // draft cleanup must not delete its photos.
    try {
      await _ref.read(incidentServiceProvider).incrementReportsCount(user.id);
    } catch (_) {}
    await clearDraft();
  }

  /// Keeps an unfinished report so the user can continue it later.
  Future<void> saveDraft(ReportDraftModel draft) async {
    final uid = _ref.read(authStateProvider).valueOrNull?.user?.id ?? '';
    if (uid.isEmpty) {
      throw const AppException('You need to be signed in to save a draft.');
    }
    await _ref.read(incidentServiceProvider).saveDraft(uid, draft);
  }

  /// The signed-in user's draft, or null. Never throws: a draft that cannot
  /// be read is treated as no draft.
  Future<ReportDraftModel?> loadDraft() async {
    try {
      // Wait for the auth check rather than reading a value that may still
      // be loading, e.g. right after a cold start.
      final auth = await _ref.read(authStateProvider.future);
      final uid = auth.user?.id ?? '';
      if (uid.isEmpty) return null;
      final draft = await _ref.read(incidentServiceProvider).getDraft(uid);
      return draft == null || draft.isEmpty ? null : draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    final uid = _ref.read(authStateProvider).valueOrNull?.user?.id ?? '';
    if (uid.isEmpty) return;
    try {
      await _ref.read(incidentServiceProvider).deleteDraft(uid);
    } catch (_) {}
  }

  Future<void> updateStatus(
    String incidentId,
    String status, {
    String? note,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull?.user;
    if (user == null || user.id.isEmpty) {
      throw const AppException('You need to be signed in.');
    }
    if (!IncidentModel.statuses.contains(status)) {
      throw AppException('Unknown status "$status".');
    }

    final service = _ref.read(incidentServiceProvider);
    // Get the current incident to check transition validity
    final incidentSnap = await service.getIncidentById(incidentId).first;
    if (incidentSnap == null) {
      throw const AppException('Report not found.');
    }
    if (!IncidentModel.canTransition(incidentSnap.status, status)) {
      throw AppException(
        'A report that is ${IncidentLabels.status(incidentSnap.status)} '
        'cannot move to ${IncidentLabels.status(status)}.',
      );
    }

    await service.updateIncidentStatus(
      incidentId: incidentId,
      newStatus: status,
      byUid: user.id,
      byName: user.name,
      note: note,
    );

    // Create notification for the reporter
    if (incidentSnap.reporterId != user.id) {
      await service.createNotification(
        NotificationModel(
          userId: incidentSnap.reporterId,
          message:
              'Your report "${incidentSnap.title}" is now '
              '${IncidentLabels.status(status)}.',
          incidentId: incidentId,
        ),
      );
    }
  }

  /// Vote on an incident.
  Future<void> vote(String incidentId) async {
    final uid = _ref.read(authStateProvider).valueOrNull?.user?.id ?? '';
    if (uid.isEmpty) {
      throw const AppException('You need to be signed in to vote.');
    }
    await _ref
        .read(incidentServiceProvider)
        .vote(incidentId: incidentId, uid: uid);
  }

  /// Remove vote from an incident.
  Future<void> unvote(String incidentId) async {
    final uid = _ref.read(authStateProvider).valueOrNull?.user?.id ?? '';
    if (uid.isEmpty) {
      throw const AppException('You need to be signed in.');
    }
    await _ref
        .read(incidentServiceProvider)
        .unvote(incidentId: incidentId, uid: uid);
  }

  /// Edit an incident (owner only, when submitted).
  Future<void> editIncident({
    required String incidentId,
    required String title,
    required String description,
    required String category,
    required String sector,
    required String location,
    required String urgency,
  }) async {
    final uid = _ref.read(authStateProvider).valueOrNull?.user?.id ?? '';
    final incident = await _ref
        .read(incidentServiceProvider)
        .getIncidentById(incidentId)
        .first;
    if (incident == null) {
      throw const AppException('Report not found.');
    }
    if (incident.reporterId != uid) {
      throw const AppException('Only the reporter can edit this report.');
    }
    if (incident.status != 'submitted') {
      throw const AppException(
        'Only reports with status "submitted" can be edited.',
      );
    }
    await _ref
        .read(incidentServiceProvider)
        .editIncident(
          incidentId: incidentId,
          title: title,
          description: description,
          category: category,
          sector: sector,
          location: location,
          urgency: urgency,
        );
  }

  /// Delete an incident (owner when submitted, or staff).
  Future<void> deleteIncident(String incidentId) async {
    final user = _ref.read(authStateProvider).valueOrNull?.user;
    final isStaff = _ref.read(authStateProvider).valueOrNull?.isStaff ?? false;
    if (user == null) {
      throw const AppException('You need to be signed in.');
    }
    final incident = await _ref
        .read(incidentServiceProvider)
        .getIncidentById(incidentId)
        .first;
    if (incident == null) {
      throw const AppException('Report not found.');
    }
    final isOwner = incident.reporterId == user.id;
    final canDelete = isStaff || (isOwner && incident.status == 'submitted');
    if (!canDelete) {
      throw const AppException(
        'You do not have permission to delete this report.',
      );
    }
    await _ref
        .read(incidentServiceProvider)
        .deleteIncident(incidentId, withFlags: isStaff);
    // Photos go last, so a failed delete cannot leave a report without them.
    await _deleteAll(_ref.read(storageServiceProvider), incident.images);
  }

  /// Flag a report as false or abusive for staff to review.
  Future<void> flagReport(String incidentId) async {
    final user = _ref.read(authStateProvider).valueOrNull?.user;
    if (user == null) {
      throw const AppException('You need to be signed in.');
    }
    await _ref
        .read(incidentServiceProvider)
        .flagIncident(incidentId: incidentId, uid: user.id);
  }

  /// Assign a report to the signed-in staff member.
  Future<void> assignToMe(String incidentId) async {
    final authState = _ref.read(authStateProvider).valueOrNull;
    final user = authState?.user;
    if (user == null || !(authState?.isStaff ?? false)) {
      throw const AppException('Only staff can assign reports.');
    }
    await _ref
        .read(incidentServiceProvider)
        .assignToStaff(
          incidentId: incidentId,
          staffUid: user.id,
          staffName: user.name,
        );
  }

  /// Get duplicate hints for a title.
  Future<List<IncidentModel>> getDuplicateHints({
    required String title,
    String? category,
  }) async {
    if (title.length < 3) return [];
    return _ref
        .read(incidentServiceProvider)
        .getDuplicateHints(title: title, category: category);
  }

  /// Mark a notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    await _ref
        .read(incidentServiceProvider)
        .markNotificationRead(notificationId);
  }

  /// Mark all notifications as read.
  Future<void> markAllNotificationsRead() async {
    final userId = _ref.read(authStateProvider).valueOrNull?.user?.id ?? '';
    if (userId.isEmpty) return;
    await _ref.read(incidentServiceProvider).markAllNotificationsRead(userId);
  }

  Future<void> _deleteAll(StorageService storage, List<String> urls) async {
    for (final url in urls) {
      await storage.deleteImage(url);
    }
  }
}
