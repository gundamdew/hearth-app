import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chore.dart';

class CleaningNotifier extends Notifier<List<Chore>> {
  @override
  List<Chore> build() {
    // Тестовые данные на основе макета
    return [
      Chore(id: 'c1', name: 'Wash dishes', category: 'Kitchen', assignee: 'Maya'),
      Chore(id: 'c2', name: 'Take out trash & recycling', category: 'Kitchen', assignee: 'Jonah'),
      Chore(id: 'c3', name: 'Vacuum living room', category: 'Living room', assignee: 'Jonah'),
      Chore(id: 'c4', name: 'Clean bathroom', category: 'Bathroom', assignee: 'Maya'),
      Chore(id: 'c5', name: 'Laundry', category: 'Bedroom', assignee: 'Maya'),
      Chore(id: 'c6', name: 'Water plants', category: 'Living room', assignee: 'Jonah'),
      Chore(id: 'c7', name: 'Wipe counters & stove', category: 'Kitchen', assignee: 'Jonah'),
      Chore(id: 'c8', name: 'Change bed sheets', category: 'Bedroom', assignee: 'Maya'),
    ];
  }

  void toggleStatus(String id) {
    state = state.map((chore) {
      if (chore.id == id) {
        return chore.copyWith(isDone: !chore.isDone);
      }
      return chore;
    }).toList();
  }

  void changeAssignee(String id) {
    state = state.map((chore) {
      if (chore.id == id) {
        final newAssignee = chore.assignee == 'Maya' ? 'Jonah' : 'Maya';
        return chore.copyWith(assignee: newAssignee);
      }
      return chore;
    }).toList();
  }

  void balanceLoad() {
    final newState = List<Chore>.from(state);

    // Математически распределяем незавершенные задачи поровну (чередованием)
    int undoneIndex = 0;
    for (int i = 0; i < newState.length; i++) {
      if (!newState[i].isDone) {
        final assignedTo = undoneIndex % 2 == 0 ? 'Maya' : 'Jonah';
        newState[i] = newState[i].copyWith(assignee: assignedTo);
        undoneIndex++;
      }
    }
    state = newState;
  }

  void swapAndNewWeek() {
    state = state.map((chore) {
      final newAssignee = chore.assignee == 'Maya' ? 'Jonah' : 'Maya';
      // Снимаем галочки и меняем ответственных местами
      return chore.copyWith(assignee: newAssignee, isDone: false);
    }).toList();
  }
}

final cleaningProvider = NotifierProvider<CleaningNotifier, List<Chore>>(() {
  return CleaningNotifier();
});