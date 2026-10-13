// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/hearth_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showResidentDialog(BuildContext context, WidgetRef ref, [AppUser? user]) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final pinCtrl = TextEditingController(text: user?.pinCode ?? '');
    Color pickedColor = user?.color ?? AppTheme.residentColors[0];

    showHearthModal(
      context: context,
      title: user == null ? 'Add Resident' : 'Edit Resident',
      sub: 'Resident',
      child: StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Vladimir'),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              Text(
                user == null ? '4-digit PIN' : 'New 4-digit PIN (leave blank to keep)',
                style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: GoogleFonts.dmMono(fontSize: 16, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '••••',
                  counterText: '',
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              Text('Signature color', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
              const SizedBox(height: 10),
              Row(
                children: AppTheme.residentColors.map((color) {
                  final isSelected = pickedColor == color;
                  return GestureDetector(
                    onTap: () => setModalState(() => pickedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: nameCtrl.text.trim().isEmpty || (user == null && pinCtrl.text.length != 4)
                      ? null
                      : () {
                          final name = nameCtrl.text.trim();
                          final pin = pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : (user?.pinCode ?? '1234');

                          if (user == null) {
                            ref.read(usersControllerProvider).addUser(name, pin, pickedColor);
                          } else {
                            ref.read(usersControllerProvider).updateUser(user.id, name, pin);
                          }
                          Navigator.pop(modalCtx);
                        },
                  child: const Text('Save resident'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (usersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.moss));
    }

    final users = usersAsync.value ?? [];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                sub: 'Household',
                title: 'Household Settings',
                action: ElevatedButton.icon(
                  onPressed: () => _showResidentDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Resident'),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: AppTheme.cardDecoration,
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.line, height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isCurrent = currentUser?.id == user.id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          HearthAvatar(name: user.name, color: user.color, size: 44),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(you)',
                                        style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.muted),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'PIN: ****',
                                  style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.muted),
                            splashRadius: 18,
                            onPressed: () => _showResidentDialog(context, ref, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.muted),
                            splashRadius: 18,
                            onPressed: isCurrent
                                ? null
                                : () => ref.read(usersControllerProvider).deleteUser(user.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}