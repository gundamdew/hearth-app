// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/hearth_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  AppUser? _selectedUser;
  String _enteredPin = '';
  bool _isError = false;
  final TextEditingController _firstNameCtrl = TextEditingController();
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleKeyPress(String key) {
    if (_selectedUser == null) {
      return;
    }

    if (key == 'Anuluj' || key == 'Cancel') {
      setState(() {
        _selectedUser = null;
        _enteredPin = '';
        _isError = false;
      });
      return;
    }

    if (key == 'Usuń' || key == 'Del') {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
          _isError = false;
        });
      }
      return;
    }

    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += key;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        if (_enteredPin == _selectedUser!.pinCode) {
          Future.delayed(const Duration(milliseconds: 180), () {
            if (mounted) {
              ref.read(currentUserProvider.notifier).login(_selectedUser!);
            }
          });
        } else {
          setState(() => _isError = true);
          _shakeController.forward(from: 0.0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nieprawidłowy PIN', style: TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.danger,
              duration: Duration(seconds: 1),
            ),
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                _enteredPin = '';
                _isError = false;
              });
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Container(
        decoration: AppTheme.canvasGradientDecoration,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Stack(
            children: [
              // Top Brand
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hearth',
                          style: AppTheme.titleStyle(fontSize: 26),
                        ),
                        TextSpan(
                          text: '.',
                          style: AppTheme.titleStyle(fontSize: 26, color: AppTheme.terra),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Auth Container
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
                  child: usersAsync.when(
                    loading: () => const CircularProgressIndicator(color: AppTheme.moss),
                    error: (err, _) => Text('Błąd ładowania użytkowników: $err', style: const TextStyle(color: AppTheme.danger)),
                    data: (users) {
                      if (_selectedUser == null) {
                        return _buildResidentPicker(context, users);
                      }
                      return _buildPinPad(context, _selectedUser!);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidentPicker(BuildContext context, List<AppUser> users) {
    if (users.isEmpty) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: AppTheme.cardDecoration,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PIERWSZY DOMOWNIK', style: AppTheme.microStyle),
            const SizedBox(height: 6),
            Text('Skonfiguruj swój dom', style: AppTheme.titleStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              'Baza danych jest pusta. Dodaj pierwszego domownika, aby rozpocząć — kolejnych dodasz w Ustawieniach.',
              style: GoogleFonts.instrumentSans(color: AppTheme.muted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(hintText: 'Twoje imię'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _firstNameCtrl.text.trim().isEmpty
                    ? null
                    : () {
                        final name = _firstNameCtrl.text.trim();
                        ref.read(usersControllerProvider).addUser(
                          name,
                          '1234',
                          AppTheme.residentColors[0],
                        );
                        _firstNameCtrl.clear();
                      },
                child: const Text('Utwórz domownika · PIN 1234'),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('WSPÓLNY DOM', style: AppTheme.microStyle),
        const SizedBox(height: 8),
        Text('Kto korzysta z ekranu?', style: AppTheme.titleStyle(fontSize: 36)),
        const SizedBox(height: 36),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: users.map((user) {
            return GestureDetector(
              onTap: () => setState(() {
                _selectedUser = user;
                _enteredPin = '';
                _isError = false;
              }),
              child: Container(
                width: 175,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HearthAvatar(
                      name: user.name,
                      color: user.color,
                      avatar: user.avatar,
                      size: 84,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: AppTheme.titleStyle(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 12, color: AppTheme.muted),
                        const SizedBox(width: 4),
                        Text(
                          'Chronione PIN-em',
                          style: GoogleFonts.instrumentSans(fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPinPad(BuildContext context, AppUser user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HearthAvatar(
          name: user.name,
          color: user.color,
          avatar: user.avatar,
          size: 56,
        ),
        const SizedBox(height: 16),
        Text('Wprowadź PIN dla: ${user.name}', style: AppTheme.titleStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text('Domyślny PIN · 1234', style: GoogleFonts.dmMono(fontSize: 12, color: AppTheme.muted)),
        const SizedBox(height: 32),

        // Dots
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final offset = _isError ? (1 - _shakeController.value) * 8 * ((_shakeController.value * 4).toInt() % 2 == 0 ? 1 : -1) : 0.0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (i) {
              final isFilled = i < _enteredPin.length;
              final dotColor = _isError ? AppTheme.danger : (isFilled ? AppTheme.moss : Colors.transparent);
              final borderColor = _isError
                  ? AppTheme.danger
                  : (isFilled ? AppTheme.moss : AppTheme.muted.withValues(alpha: 0.35));

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 36),

        // 3x4 keypad
        Container(
          constraints: const BoxConstraints(maxWidth: 270),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              '1', '2', '3',
              '4', '5', '6',
              '7', '8', '9',
              'Anuluj', '0', 'Usuń'
            ].map((key) => _buildKeyButton(key)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyButton(String key) {
    final isAction = key == 'Anuluj' || key == 'Usuń';

    return GestureDetector(
      onTap: () => _handleKeyPress(key),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: isAction
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppTheme.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(30, 32, 29, 0.03),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
        alignment: Alignment.center,
        child: Text(
          key,
          style: isAction
              ? GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.muted,
                )
              : GoogleFonts.dmMono(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.ink,
                ),
        ),
      ),
    );
  }
}