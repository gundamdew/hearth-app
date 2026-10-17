// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/hearth_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showResidentDialog(BuildContext context, WidgetRef ref, [AppUser? user]) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final pinCtrl = TextEditingController(text: user?.pinCode ?? '');
    final avatarCtrl = TextEditingController(text: user?.avatar ?? '');
    Color pickedColor = user?.color ?? AppTheme.residentColors[0];
    String? pickedAvatar = user?.avatar;

    const avatarPresets = [
      '🦊', '🐱', '🐼', '🐻', '🐰', '🦁', '🌿', '☕',
      '🍕', '🏡', '🎨', '🚀', '🎮', '⚡', '🌻', '✨',
    ];

    showHearthModal(
      context: context,
      title: user == null ? 'Dodaj domownika' : 'Edytuj domownika',
      sub: 'Domownik',
      child: StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar preview & header
                Center(
                  child: Column(
                    children: [
                      HearthAvatar(
                        name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : '?',
                        color: pickedColor,
                        avatar: pickedAvatar,
                        size: 56,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Podgląd awatara',
                        style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text('Imię', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'np. Vladimir'),
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: 16),

                // PIN
                Text(
                  user == null ? '4-cyfrowy PIN' : 'Nowy 4-cyfrowy PIN (pozostaw puste, aby zachować)',
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

                // Avatar Presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Wybierz awatar', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                    if (pickedAvatar != null)
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            pickedAvatar = null;
                            avatarCtrl.clear();
                          });
                        },
                        child: Text(
                          'Wyczyść (użyj inicjałów)',
                          style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.terra, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: avatarPresets.map((emoji) {
                    final isSelected = pickedAvatar == emoji;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          pickedAvatar = emoji;
                          avatarCtrl.text = emoji;
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.moss.withValues(alpha: 0.15) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.moss : AppTheme.line,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Custom Avatar Input (URL or custom emoji)
                Text('Własny awatar (link URL lub własne emoji)', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: avatarCtrl,
                  decoration: const InputDecoration(
                    hintText: 'https://... lub dowolne emoji',
                    prefixIcon: Icon(Icons.link, size: 18, color: AppTheme.muted),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      pickedAvatar = val.trim().isNotEmpty ? val.trim() : null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Color Selection
                Text('Kolor profilu', style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.muted)),
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

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: nameCtrl.text.trim().isEmpty || (user == null && pinCtrl.text.length != 4)
                        ? null
                        : () {
                            final name = nameCtrl.text.trim();
                            final pin = pinCtrl.text.trim().isNotEmpty ? pinCtrl.text.trim() : (user?.pinCode ?? '1234');
                            final avatar = pickedAvatar?.trim().isNotEmpty == true ? pickedAvatar!.trim() : null;

                            if (user == null) {
                              ref.read(usersControllerProvider).addUser(name, pin, pickedColor, avatar);
                            } else {
                              ref.read(usersControllerProvider).updateUser(user.id, name, pin, pickedColor, avatar);
                              final currentUser = ref.read(currentUserProvider);
                              if (currentUser?.id == user.id) {
                                ref.read(currentUserProvider.notifier).login(
                                  currentUser!.copyWith(
                                    name: name,
                                    pinCode: pin,
                                    color: pickedColor,
                                    avatar: avatar,
                                  ),
                                );
                              }
                            }
                            Navigator.pop(modalCtx);
                          },
                    child: const Text('Zapisz domownika'),
                  ),
                ),
              ],
            ),
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
              // Notification Settings Card
              const SectionHeader(
                sub: 'Powiadomienia',
                title: 'Powiadomienia Push',
              ),
              const SizedBox(height: 8),
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Push Notifications',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Otrzymuj alerty o wydatkach, zadaniach i stanie zapasów na bieżąco.',
                                style: GoogleFonts.instrumentSans(fontSize: 13, color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: currentUser?.notificationsEnabled ?? true,
                          activeTrackColor: AppTheme.moss,
                          onChanged: currentUser == null
                              ? null
                              : (bool val) async {
                                  final updated = currentUser.copyWith(notificationsEnabled: val);
                                  ref.read(currentUserProvider.notifier).updateCurrentUser(updated);
                                  await ref
                                      .read(pushNotificationServiceProvider)
                                      .toggleNotificationsEnabled(currentUser.id, val);
                                  if (val) {
                                    await ref
                                        .read(pushNotificationServiceProvider)
                                        .initAndRegisterUser(updated);
                                  } else {
                                    await ref
                                        .read(pushNotificationServiceProvider)
                                        .unregisterUser(updated);
                                  }
                                },
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.line, height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Sprawdź działanie powiadomień i szuflady Hearth Pulse',
                            style: GoogleFonts.instrumentSans(fontSize: 13, color: AppTheme.muted),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: currentUser == null
                              ? null
                              : () async {
                                  await ref
                                      .read(notificationControllerProvider)
                                      .sendTestNotification(currentUser.name);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Wysłano testowe powiadomienie do Hearth Pulse!'),
                                        backgroundColor: AppTheme.moss,
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.send_outlined, size: 16),
                          label: const Text('Send Test Notification'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Residents Settings Card
              SectionHeader(
                sub: 'Domownicy',
                title: 'Ustawienia domowników',
                action: ElevatedButton.icon(
                  onPressed: () => _showResidentDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Dodaj domownika'),
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
                          HearthAvatar(name: user.name, color: user.color, avatar: user.avatar, size: 44),
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
                                        '(Ty)',
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
                            tooltip: 'Edytuj domownika',
                            onPressed: () => _showResidentDialog(context, ref, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.muted),
                            splashRadius: 18,
                            tooltip: 'Usuń domownika',
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