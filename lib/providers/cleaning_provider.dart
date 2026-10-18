import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chore.dart';
import 'notifications_provider.dart';

final cleaningProvider = StreamProvider<List<Chore>>((ref) {
  return FirebaseFirestore.instance.collection('chores').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => Chore.fromFirestore(doc.data(), doc.id)).toList(),
  );
});

final cleaningControllerProvider = Provider((ref) => CleaningController(ref));

class CleaningController {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  CleaningController(this._ref);

  Future<void> addChore(String name, String category, String assignee) async {
    final chore = Chore(id: '', name: name, category: category, assignee: assignee);
    await _db.collection('chores').add(chore.toMap());
  }

  Future<void> deleteChore(String id) async {
    await _db.collection('chores').doc(id).delete();
  }

  Future<void> toggleStatus(
    String id,
    bool currentStatus, {
    Chore? chore,
    String? actorName,
  }) async {
    final nextStatus = !currentStatus;
    await _db.collection('chores').doc(id).update({'isDone': nextStatus});

    if (nextStatus) {
      Chore? targetChore = chore;
      if (targetChore == null) {
        final doc = await _db.collection('chores').doc(id).get();
        final data = doc.data();
        if (data != null) {
          targetChore = Chore.fromFirestore(data, doc.id);
        }
      }

      if (targetChore != null) {
        await _ref.read(notificationControllerProvider).dispatchNotification(
          title: 'Chore Completed',
          body: '${targetChore.assignee} finished: ${targetChore.name}.',
          category: 'cleaning',
          actorName: actorName ?? targetChore.assignee,
        );
      }
    }
  }

  Future<void> changeAssignee(String id, String currentAssignee, List<String> availableUsers) async {
    if (availableUsers.isEmpty) {
      return;
    }
    final currentIndex = availableUsers.indexOf(currentAssignee);
    final nextIndex = (currentIndex + 1) % availableUsers.length;
    await _db.collection('chores').doc(id).update({'assignee': availableUsers[nextIndex]});
  }

  Future<void> balanceLoad(List<Chore> currentChores, List<String> availableUsers) async {
    if (availableUsers.isEmpty) {
      return;
    }
    final batch = _db.batch();
    int undoneIndex = 0;

    for (var chore in currentChores) {
      if (!chore.isDone) {
        final assignedTo = availableUsers[undoneIndex % availableUsers.length];
        batch.update(_db.collection('chores').doc(chore.id), {'assignee': assignedTo});
        undoneIndex++;
      }
    }
    await batch.commit();
  }

  Future<void> swapAndNewWeek(
    List<Chore> currentChores,
    List<String> availableUsers, {
    String? actorName,
  }) async {
    if (availableUsers.isEmpty) {
      return;
    }
    final batch = _db.batch();

    for (var chore in currentChores) {
      final currentIndex = availableUsers.indexOf(chore.assignee);
      final nextIndex = currentIndex != -1 ? (currentIndex + 1) % availableUsers.length : 0;
      batch.update(_db.collection('chores').doc(chore.id), {
        'assignee': availableUsers[nextIndex],
        'isDone': false,
      });
    }
    await batch.commit();

    await _ref.read(notificationControllerProvider).dispatchNotification(
      title: 'New Cleaning Week',
      body: 'Chores have been rotated for the new week.',
      category: 'cleaning',
      actorName: actorName ?? 'System',
    );
  }
}