import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/history_entry_model.dart';
import '../models/incident_model.dart';
import '../models/notification_model.dart';
import '../models/report_draft_model.dart';
import '../models/vote_model.dart';

class IncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  /// Creates the report and its first "submitted" history entry in one
  /// batch, so a report never exists without its history.
  Future<String> createIncident(IncidentModel incident) async {
    final docRef = _incidents.doc();
    final historyRef = docRef.collection('history').doc();
    final entry = HistoryEntryModel(
      fromStatus: '',
      toStatus: incident.status,
      byUid: incident.reporterId,
      byName: incident.reporterName,
    );

    final batch = _firestore.batch();
    batch.set(docRef, incident.toJson());
    batch.set(historyRef, entry.toJson());
    await batch.commit();
    return docRef.id;
  }

  /// Live list of incidents, newest first. Category, status, urgency and
  /// reporter filters run in Firestore and need the composite indexes defined
  /// in firestore.indexes.json. Text search is applied on the client.
  Stream<List<IncidentModel>> getIncidentsStream({
    String? category,
    String? status,
    String? urgency,
    String? reporterId,
  }) {
    Query<Map<String, dynamic>> query = _incidents;

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (urgency != null && urgency.isNotEmpty) {
      query = query.where('urgency', isEqualTo: urgency);
    }
    if (reporterId != null && reporterId.isNotEmpty) {
      query = query.where('reporterId', isEqualTo: reporterId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IncidentModel.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<IncidentModel?> getIncidentById(String id) {
    return _incidents.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return IncidentModel.fromJson(doc.id, doc.data()!);
    });
  }

  /// Updates the status and writes a history entry in a batch.
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String newStatus,
    required String byUid,
    required String byName,
    String? note,
  }) async {
    final incidentRef = _incidents.doc(incidentId);
    final snapshot = await incidentRef.get();
    if (!snapshot.exists) throw Exception('Incident not found');

    final currentStatus = snapshot.data()!['status'] as String;

    final historyEntry = HistoryEntryModel(
      fromStatus: currentStatus,
      toStatus: newStatus,
      byUid: byUid,
      byName: byName,
      note: note,
    );

    final historyRef = incidentRef.collection('history').doc();
    final now = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    final updates = <String, dynamic>{'status': newStatus, 'updatedAt': now};
    if (newStatus == 'resolved') {
      updates['resolvedAt'] = now;
    }
    batch.update(incidentRef, updates);
    batch.set(historyRef, historyEntry.toJson());

    await batch.commit();
  }

  /// Stream of history entries for an incident, ordered by time.
  Stream<List<HistoryEntryModel>> getHistoryStream(String incidentId) {
    return _incidents
        .doc(incidentId)
        .collection('history')
        .orderBy('at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HistoryEntryModel.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  /// User votes on an incident. The vote document and the count change in
  /// one transaction, which the security rules require. Voting twice is a
  /// no-op, so a double tap cannot inflate the count.
  Future<void> vote({required String incidentId, required String uid}) async {
    final incidentRef = _incidents.doc(incidentId);
    final voteRef = incidentRef.collection('votes').doc(uid);
    await _firestore.runTransaction((transaction) async {
      // Firestore transactions must do all reads before any write.
      final incidentSnap = await transaction.get(incidentRef);
      final voteSnap = await transaction.get(voteRef);
      if (!incidentSnap.exists || voteSnap.exists) return;
      final currentCount =
          (incidentSnap.data()?['upvoteCount'] as num?)?.toInt() ?? 0;
      transaction.set(voteRef, VoteModel(uid: uid).toJson());
      transaction.update(incidentRef, {'upvoteCount': currentCount + 1});
    });
  }

  /// User removes their vote. Removing a vote that does not exist is a no-op.
  Future<void> unvote({required String incidentId, required String uid}) async {
    final incidentRef = _incidents.doc(incidentId);
    final voteRef = incidentRef.collection('votes').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final incidentSnap = await transaction.get(incidentRef);
      final voteSnap = await transaction.get(voteRef);
      if (!voteSnap.exists) return;
      final currentCount =
          (incidentSnap.data()?['upvoteCount'] as num?)?.toInt() ?? 0;
      transaction.delete(voteRef);
      // The rules only accept a drop of exactly one, so a count that is
      // already zero is left alone.
      if (currentCount > 0) {
        transaction.update(incidentRef, {'upvoteCount': currentCount - 1});
      }
    });
  }

  /// Checks whether the user has voted on an incident.
  Stream<bool> getVoteStatus({
    required String incidentId,
    required String uid,
  }) {
    return _incidents
        .doc(incidentId)
        .collection('votes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Edits an incident (owner only, when status is submitted).
  Future<void> editIncident({
    required String incidentId,
    required String title,
    required String description,
    required String category,
    required String sector,
    required String location,
    required String urgency,
  }) async {
    await _incidents.doc(incidentId).update({
      'title': title,
      'description': description,
      'category': category,
      'sector': sector,
      'location': location,
      'urgency': urgency,
      'searchKeywords': IncidentModel.generateSearchKeywords(title),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes an incident (owner when submitted, or staff).
  Future<void> deleteIncident(String incidentId) async {
    // Delete associated images from Storage is handled by the caller
    await _incidents.doc(incidentId).delete();
  }

  /// Assigns a report to a staff member.
  Future<void> assignToStaff({
    required String incidentId,
    required String staffUid,
    required String staffName,
  }) async {
    await _incidents.doc(incidentId).update({
      'assignedTo': staffUid,
      'assignedToName': staffName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns similar open reports based on title keywords.
  Future<List<IncidentModel>> getDuplicateHints({
    required String title,
    String? category,
    String? excludeId,
  }) async {
    final keywords = IncidentModel.generateSearchKeywords(title);
    if (keywords.isEmpty) return [];

    // A single array-contains filter needs no composite index. Status and
    // category are filtered here instead of in the query.
    const openStatuses = ['submitted', 'in_review', 'in_progress'];
    final snapshot = await _incidents
        .where('searchKeywords', arrayContains: keywords.first)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => IncidentModel.fromJson(doc.id, doc.data()))
        .where((inc) => inc.id != excludeId)
        .where((inc) => openStatuses.contains(inc.status))
        .where(
          (inc) =>
              category == null || category.isEmpty || inc.category == category,
        )
        .take(5)
        .toList();
  }

  /// Stream of notifications for a user.
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Creates a notification for a user.
  Future<void> createNotification(NotificationModel notification) async {
    await _notifications.add(notification.toJson());
  }

  /// Marks a notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'read': true});
  }

  /// Marks all notifications for a user as read.
  Future<void> markAllNotificationsRead(String userId) async {
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Increments the reportsSubmitted count for a user.
  Future<void> incrementReportsCount(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'reportsSubmitted': FieldValue.increment(1),
    });
  }

  DocumentReference<Map<String, dynamic>> _draftDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('drafts').doc('current');

  /// Saves the user's draft. Offline, Firestore keeps the write in its local
  /// cache and only completes the future once the server confirms, so the
  /// wait is capped: the draft is already safe on the device and syncs later.
  Future<void> saveDraft(String uid, ReportDraftModel draft) async {
    await _draftDoc(uid)
        .set(draft.toJson())
        .timeout(const Duration(seconds: 3), onTimeout: () {});
  }

  /// The user's draft, or null if there is none. Falls back to the local
  /// cache when offline.
  Future<ReportDraftModel?> getDraft(String uid) async {
    final doc = await _draftDoc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ReportDraftModel.fromJson(data);
  }

  Future<void> deleteDraft(String uid) async {
    await _draftDoc(uid).delete().timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
  }

  Stream<int> getCountByStatusStream(String status) {
    return _incidents
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
