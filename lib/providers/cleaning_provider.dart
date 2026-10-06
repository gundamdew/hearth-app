import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chore.dart';

class CleaningNotifier extends Notifier<List<Chore>> {
  @override
  List<Chore> build() {
    return [
      Chore(id: 'c1', name: 'Wash dishes', category: 'Kitchen', assignee: 'Maya'),
      Chore(id: 'c2', name: 'Take out trash', category: 'Kitchen', assignee: 'Jonah'),
      Chore(id: 'c3', name: 'Vacuum living room', category: 'Living room', assignee: 'Jonah'),
      Chore(id: 'c4', name: 'Clean bathroom', category: 'Bathroom', assignee: 'Maya'),
    ];
  }

  void addChore(String name, String category, String assignee) {
    final newChore = Chore(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      assignee: assignee,
    );
    state = [...state, newChore];
  }

  void deleteChore(String id) {
    state = state.where((chore) => chore.id != id).toList();
  }

  void toggleStatus(String id) {
    state = state.map((chore) {
      if (chore.id == id) return chore.copyWith(isDone: !chore.isDone);
      return chore;
    }).toList();
  }

  void changeAssignee(String id, List<String> availableUsers) {
    if (availableUsers.isEmpty) return;
    
    state = state.map((chore) {
      if (chore.id == id) {
        final currentIndex = availableUsers.indexOf(chore.assignee);
        final nextIndex = (currentIndex + 1) % availableUsers.length;
        return chore.copyWith(assignee: availableUsers[nextIndex]);
      }
      return chore;
    }).toList();
  }

  void balanceLoad(List<String> availableUsers) {
    if (availableUsers.isEmpty) return;
    final newState = List<Chore>.from(state);
    int undoneIndex = 0;
    
    for (int i = 0; i < newState.length; i++) {
      if (!newState[i].isDone) {
        final assignedTo = availableUsers[undoneIndex % availableUsers.length];
        newState[i] = newState[i].copyWith(assignee: assignedTo);
        undoneIndex++;
      }
    }
    state = newState;
  }

  void swapAndNewWeek(List<String> availableUsers) {
    if (availableUsers.isEmpty) return;
    state = state.map((chore) {
      final currentIndex = availableUsers.indexOf(chore.assignee);
      final nextIndex = currentIndex != -1 ? (currentIndex + 1) % availableUsers.length : 0;
      return chore.copyWith(assignee: availableUsers[nextIndex], isDone: false);
    }).toList();
  }
}

final cleaningProvider = NotifierProvider<CleaningNotifier, List<Chore>>(() => CleaningNotifier());