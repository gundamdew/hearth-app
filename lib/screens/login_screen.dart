import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  AppUser? _selectedUser;
  String _enteredPin = '';

  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  void _handleKeyPress(String key) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += key);
      if (_enteredPin.length == 4) {
        if (_enteredPin == _selectedUser!.pinCode) {
          ref.read(currentUserProvider.notifier).login(_selectedUser!); // ИЗМЕНЕНО
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.red));
          setState(() => _enteredPin = '');
        }
      }
    }
  }

  void _createFirstUser() {
    if (_nameCtrl.text.isNotEmpty && _pinCtrl.text.length >= 4) {
      ref.read(usersControllerProvider).addUser(_nameCtrl.text, _pinCtrl.text, AppTheme.terracotta);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      body: Center(
        child: usersAsync.when(
          loading: () => const CircularProgressIndicator(color: AppTheme.mossGreen),
          error: (err, stack) => Text('Error loading users: $err'),
          data: (users) {
            if (users.isEmpty) {
              return _buildFirstUserForm();
            }

            if (_selectedUser == null) {
              return _buildUserSelection(users);
            }

            return _buildPinPad();
          },
        ),
      ),
    );
  }

  Widget _buildFirstUserForm() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: AppTheme.cardBackground, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.1))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Welcome to Hearth.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28)),
          const SizedBox(height: 8),
          const Text('Let\'s create your first resident profile.', style: TextStyle(color: AppTheme.textLight)),
          const SizedBox(height: 32),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Name')),
          const SizedBox(height: 16),
          TextField(controller: _pinCtrl, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, decoration: const InputDecoration(hintText: '4-Digit PIN')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _createFirstUser, child: const Text('Create Profile'))),
        ],
      ),
    );
  }

  Widget _buildUserSelection(List<AppUser> users) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Who is using the screen?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 32)),
        const SizedBox(height: 48),
        Wrap(
          spacing: 32,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: users.map((user) => GestureDetector(
            onTap: () => setState(() {
              _selectedUser = user;
              _enteredPin = '';
            }),
            child: Column(
              children: [
                CircleAvatar(radius: 48, backgroundColor: user.color.withValues(alpha: 0.2), child: Text(user.name[0], style: TextStyle(color: user.color, fontSize: 32, fontWeight: FontWeight.bold))),
                const SizedBox(height: 16),
                Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildPinPad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Enter PIN for ${_selectedUser!.name}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _enteredPin.length ? AppTheme.mossGreen : AppTheme.textLight.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: 280,
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 1; i <= 9; i++) _buildPinButton(i.toString()),
              _buildPinButton('Cancel', isAction: true),
              _buildPinButton('0'),
              _buildPinButton('Del', isAction: true),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPinButton(String label, {bool isAction = false}) {
    return GestureDetector(
      onTap: () {
        if (label == 'Cancel') setState(() => _selectedUser = null);
        else if (label == 'Del') setState(() => _enteredPin = _enteredPin.isNotEmpty ? _enteredPin.substring(0, _enteredPin.length - 1) : '');
        else _handleKeyPress(label);
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(shape: BoxShape.circle, color: isAction ? Colors.transparent : AppTheme.cardBackground, border: isAction ? null : Border.all(color: AppTheme.textLight.withValues(alpha: 0.1))),
        child: Center(
          child: Text(label, style: GoogleFonts.instrumentSans(fontSize: isAction ? 16 : 24, fontWeight: isAction ? FontWeight.w600 : FontWeight.w500, color: isAction ? AppTheme.textLight : AppTheme.textDark)),
        ),
      ),
    );
  }
}