import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/chore.dart';
import '../providers/cleaning_provider.dart';

class CleaningScreen extends ConsumerWidget {
  const CleaningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chores = ref.watch(cleaningProvider);

    // Статистика для прогресс-баров
    final mayaTasks = chores.where((c) => c.assignee == 'Maya').toList();
    final jonahTasks = chores.where((c) => c.assignee == 'Jonah').toList();
    
    final mayaCompleted = mayaTasks.where((c) => c.isDone).length;
    final jonahCompleted = jonahTasks.where((c) => c.isDone).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Верхний блок: Карточки пользователей и кнопки управления[cite: 11]
        Row(
          children: [
            Expanded(child: _buildUserCard('Maya', mayaCompleted, mayaTasks.length, AppTheme.terracotta)),
            const SizedBox(width: 24),
            Expanded(child: _buildUserCard('Jonah', jonahCompleted, jonahTasks.length, AppTheme.sage)),
            const SizedBox(width: 48),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => ref.read(cleaningProvider.notifier).balanceLoad(),
                  child: const Text('Balance load'),
                ),
                TextButton(
                  onPressed: () => ref.read(cleaningProvider.notifier).swapAndNewWeek(),
                  child: const Text('Swap & new week'),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 32),

        // Сетка задач[cite: 11]
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
                    itemBuilder: (context, index) {
                      return _buildChoreRow(context, ref, chores[index]);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildAddTaskForm(),
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
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              name[0],
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    Text(
                      '$completed/$total',
                      style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.textLight.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoreRow(BuildContext context, WidgetRef ref, Chore chore) {
    final isMaya = chore.assignee == 'Maya';
    final userColor = isMaya ? AppTheme.terracotta : AppTheme.sage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Название и категория
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chore.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: chore.isDone ? TextDecoration.lineThrough : null,
                    color: chore.isDone ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chore.category,
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          
          // Тег ответственного (Кликабельный для смены)
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => ref.read(cleaningProvider.notifier).changeAssignee(chore.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: userColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chore.assignee,
                    style: TextStyle(
                      color: userColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Чекбокс статуса (Один на задачу, согласно модели)
          Checkbox(
            value: chore.isDone,
            activeColor: AppTheme.mossGreen,
            onChanged: (bool? value) {
              ref.read(cleaningProvider.notifier).toggleStatus(chore.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddTaskForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textLight.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('Add a task', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: _buildSimpleTextField('e.g. Mop kitchen floor')),
          const SizedBox(width: 12),
          Expanded(flex: 1, child: _buildSimpleTextField('Kitchen')),
          const SizedBox(width: 12),
          Expanded(flex: 1, child: _buildSimpleTextField('Maya', isDropdown: true)),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            child: const Text('Add task'),
          )
        ],
      ),
    );
  }

  Widget _buildSimpleTextField(String hint, {bool isDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
          if (isDropdown) Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textLight),
        ],
      ),
    );
  }
}