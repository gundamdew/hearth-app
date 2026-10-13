// lib/screens/cleaning_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../providers/cleaning_provider.dart';
import '../providers/users_provider.dart';
import '../widgets/hearth_ui.dart';

class CleaningScreen extends ConsumerStatefulWidget {
  const CleaningScreen({super.key});

  @override
  ConsumerState<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends ConsumerState<CleaningScreen> {
  final TextEditingController _taskNameCtrl = TextEditingController();
  final TextEditingController _roomCtrl = TextEditingController(text: 'Kuchnia');
  String? _selectedAssignee;

  @override
  void dispose() {
    _taskNameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    final choresAsync = ref.watch(cleaningProvider);
    final usersAsync = ref.watch(usersProvider);

    if (choresAsync.isLoading || usersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.moss));
    }

    final chores = choresAsync.value ?? [];
    final users = usersAsync.value ?? [];
    final userNames = users.map((u) => u.name).toList();

    if (_selectedAssignee == null && users.isNotEmpty) {
      _selectedAssignee = users.first.name;
    }

    final topResidentCards = LayoutBuilder(
      builder: (context, constraints) {
        final useTwoCols = constraints.maxWidth >= 450;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: useTwoCols ? 2 : 1,
            mainAxisExtent: 88,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userChores = chores.where((c) => c.assignee == user.name).toList();
            final doneCount = userChores.where((c) => c.isDone).length;
            final ratio = userChores.isNotEmpty ? (doneCount / userChores.length) : 0.0;

            return Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  HearthAvatar(
                    name: user.name,
                    color: user.color,
                    avatar: user.avatar,
                    size: 44,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$doneCount/${userChores.length}',
                              style: GoogleFonts.dmMono(fontSize: 13, color: AppTheme.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        HearthProgressBar(
                          value: ratio,
                          color: user.color,
                          dangerThreshold: 2.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final actionButtons = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            ref.read(cleaningControllerProvider).balanceLoad(chores, userNames);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Zadania zostały równomiernie podzielone'), backgroundColor: AppTheme.moss),
            );
          },
          icon: const Icon(Icons.balance, size: 16),
          label: const Text('Wyrównaj zadania'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            ref.read(cleaningControllerProvider).swapAndNewWeek(chores, userNames);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nowy tydzień — rotacja przypisań wykonana'), backgroundColor: AppTheme.moss),
            );
          },
          icon: const Icon(Icons.sync, size: 16),
          label: const Text('Nowy tydzień i rotacja'),
        ),
      ],
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Workload Header
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: topResidentCards),
                const SizedBox(width: 24),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: actionButtons,
                ),
              ],
            ),
          ] else ...[
            topResidentCards,
            const SizedBox(height: 16),
            actionButtons,
          ],
          const SizedBox(height: 32),

          // Main Chores Card
          Container(
            decoration: AppTheme.cardDecoration,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: SectionHeader(
                    sub: 'W tym tygodniu',
                    title: 'Obowiązki domowe',
                    action: Text(
                      'Dotknij osoby, aby zmienić przypisanie',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ),
                ),
                if (chores.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Brak dodanych zadań.', style: AppTheme.titleStyle(fontSize: 18, color: AppTheme.muted)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: chores.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
                    itemBuilder: (context, index) {
                      final chore = chores[index];
                      final userMatches = users.where((u) => u.name == chore.assignee);
                      final assignedUser = userMatches.isNotEmpty ? userMatches.first : null;

                      return Dismissible(
                        key: Key(chore.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppTheme.danger,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Usuń', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        onDismissed: (_) {
                          ref.read(cleaningControllerProvider).deleteChore(chore.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Usunięto "${chore.name}"'),
                              backgroundColor: AppTheme.ink,
                              action: SnackBarAction(
                                label: 'COFNIJ',
                                textColor: AppTheme.sage,
                                onPressed: () {
                                  ref.read(cleaningControllerProvider).addChore(
                                    chore.name,
                                    chore.category,
                                    chore.assignee,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          child: Row(
                            children: [
                              HearthCheckbox(
                                checked: chore.isDone,
                                onChange: () {
                                  ref.read(cleaningControllerProvider).toggleStatus(chore.id, chore.isDone);
                                },
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chore.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: chore.isDone ? AppTheme.muted : AppTheme.ink,
                                        decoration: chore.isDone ? TextDecoration.lineThrough : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      chore.category,
                                      style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ResidentBadge(
                                name: chore.assignee,
                                color: assignedUser?.color,
                                avatar: assignedUser?.avatar,
                                onTap: () {
                                  ref.read(cleaningControllerProvider).changeAssignee(
                                    chore.id,
                                    chore.assignee,
                                    userNames,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Add Task Bar at bottom of card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(247, 245, 240, 0.6),
                    border: Border(top: BorderSide(color: AppTheme.line)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useHorizontal = constraints.maxWidth >= 600;

                      final taskInput = TextField(
                        controller: _taskNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'np. Odkamienić czajnik',
                          fillColor: Colors.white,
                        ),
                      );

                      final roomInput = TextField(
                        controller: _roomCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Kuchnia',
                          fillColor: Colors.white,
                        ),
                      );

                      final assigneeSelect = HearthSelect<String>(
                        value: _selectedAssignee ?? '',
                        items: userNames,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedAssignee = val);
                        },
                        labelBuilder: (name) => name,
                      );

                      final addBtn = ElevatedButton.icon(
                        onPressed: () {
                          final name = _taskNameCtrl.text.trim();
                          final room = _roomCtrl.text.trim().isEmpty ? 'Kuchnia' : _roomCtrl.text.trim();
                          final assignee = _selectedAssignee ?? (userNames.isNotEmpty ? userNames.first : '');

                          if (name.isNotEmpty && assignee.isNotEmpty) {
                            ref.read(cleaningControllerProvider).addChore(name, room, assignee);
                            _taskNameCtrl.clear();
                            FocusScope.of(context).unfocus();
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Dodaj zadanie'),
                      );

                      if (useHorizontal) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nazwa zadania', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                                  const SizedBox(height: 6),
                                  taskInput,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pomieszczenie', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                                  const SizedBox(height: 6),
                                  roomInput,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Osoba', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                                  const SizedBox(height: 6),
                                  assigneeSelect,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            addBtn,
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Nazwa zadania', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                          const SizedBox(height: 6),
                          taskInput,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pomieszczenie', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                                    const SizedBox(height: 6),
                                    roomInput,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Osoba', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                                    const SizedBox(height: 6),
                                    assigneeSelect,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          addBtn,
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}