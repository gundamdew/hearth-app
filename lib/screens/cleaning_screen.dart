import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/chore.dart';
import '../providers/cleaning_provider.dart';
import '../providers/users_provider.dart';
import '../models/user_model.dart';

class CleaningScreen extends ConsumerStatefulWidget {
  const CleaningScreen({super.key});

  @override
  ConsumerState<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends ConsumerState<CleaningScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String? _selectedAssignee;

  @override
  void dispose() {
    _taskController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submitChore() {
    final name = _taskController.text.trim();
    final category = _categoryController.text.trim();
    
    if (name.isNotEmpty && _selectedAssignee != null) {
      ref.read(cleaningProvider.notifier).addChore(name, category.isEmpty ? 'General' : category, _selectedAssignee!);
      _taskController.clear();
      _categoryController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chores = ref.watch(cleaningProvider);
    final users = ref.watch(usersProvider);
    final userNames = users.map((u) => u.name).toList();

    // Защита: если юзеров нет, ставим заглушку
    if (_selectedAssignee == null && users.isNotEmpty) {
      _selectedAssignee = users.first.name;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Динамические карточки пользователей
        Row(
          children: [
            ...users.map((user) {
              final userTasks = chores.where((c) => c.assignee == user.name).toList();
              final completed = userTasks.where((c) => c.isDone).length;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: _buildUserCard(user.name, completed, userTasks.length, user.color),
                ),
              );
            }),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => ref.read(cleaningProvider.notifier).balanceLoad(userNames),
                  child: const Text('Balance load'),
                ),
                TextButton(
                  onPressed: () => ref.read(cleaningProvider.notifier).swapAndNewWeek(userNames),
                  child: const Text('Swap & new week'),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 32),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: chores.length,
                    separatorBuilder: (context, index) => Divider(color: AppTheme.textLight.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) => _buildChoreRow(context, chores[index], userNames),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAddTaskForm(users.map((u) => u.name).toList()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(String name, int completed, int total, Color color) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1))),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    Text('$completed/$total', style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.textLight)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, backgroundColor: AppTheme.textLight.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4, borderRadius: BorderRadius.circular(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoreRow(BuildContext context, Chore chore, List<String> availableUsers) {
    final users = ref.watch(usersProvider);
    // Ищем цвет пользователя. Если пользователь удален, ставим серый.
    final userColor = users.firstWhere((u) => u.name == chore.assignee, orElse: () => AppUser(id: '', name: '', pinCode: '', color: AppTheme.textLight)).color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chore.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, decoration: chore.isDone ? TextDecoration.lineThrough : null, color: chore.isDone ? AppTheme.textLight : AppTheme.textDark)),
                const SizedBox(height: 4),
                Text(chore.category, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => ref.read(cleaningProvider.notifier).changeAssignee(chore.id, availableUsers),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: userColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(chore.assignee, style: TextStyle(color: userColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          Checkbox(value: chore.isDone, activeColor: AppTheme.mossGreen, onChanged: (_) => ref.read(cleaningProvider.notifier).toggleStatus(chore.id)),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.red, size: 20), onPressed: () => ref.read(cleaningProvider.notifier).deleteChore(chore.id)),
        ],
      ),
    );
  }

  Widget _buildAddTaskForm(List<String> userNames) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.textLight.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Text('Add a task', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildTextField(_taskController, 'e.g. Mop kitchen floor')),
          const SizedBox(width: 12),
          Expanded(flex: 1, child: _buildTextField(_categoryController, 'Kitchen')),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedAssignee,
                  items: userNames.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setState(() => _selectedAssignee = val),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: _submitChore, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)), child: const Text('Add task'))
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.2)), borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.mossGreen), borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}