import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showUserDialog(BuildContext context, WidgetRef ref, [AppUser? user]) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final pinController = TextEditingController(text: user?.pinCode ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user == null ? 'Add Resident' : 'Edit Resident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(labelText: '4-Digit PIN'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && pinController.text.length >= 4) {
                  if (user == null) {
                    // Генерируем случайный цвет для новых пользователей
                    final colors = [AppTheme.amber, Colors.blueGrey, Colors.teal, Colors.indigo];
                    final randomColor = colors[DateTime.now().millisecondsSinceEpoch % colors.length];
                    ref.read(usersProvider.notifier).addUser(nameController.text, pinController.text, randomColor);
                  } else {
                    ref.read(usersProvider.notifier).updateUser(user.id, nameController.text, pinController.text);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Household Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Resident'),
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
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) => Divider(color: AppTheme.textLight.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.color.withValues(alpha: 0.2),
                    child: Text(user.name[0], style: TextStyle(color: user.color, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('PIN: ****'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.textLight), onPressed: () => _showUserDialog(context, ref, user)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.red),
                        onPressed: () => ref.read(usersProvider.notifier).deleteUser(user.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }
}