import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_notifier.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _onKeyPress(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitPin() async {
    setState(() {
      _isLoading = true;
    });

    final success = await ref.read(authProvider.notifier).verifyPin(_pin);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) {
          _pin = '';
          final globalError = ref.read(authProvider).errorMessage;
          _errorMessage = globalError ?? 'Incorrect PIN / गलत पिन';
        }
      });
    }
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: _isLoading ? null : () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 72,
        width: 72,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBD5E1)),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final staffName = authState.user?.name ?? 'Staff';
    final restName = authState.user?.restaurantName ?? 'BhojanOS';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding Header
                Text(
                  restName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003893),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Terminal Locked for $staffName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final filled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? const Color(0xFFC8102E) : Colors.transparent,
                        border: Border.all(
                          color: filled ? const Color(0xFFC8102E) : const Color(0xFF94A3B8),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Error Message banner
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFC8102E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  const SizedBox(height: 20),

                const SizedBox(height: 16),

                // Keypad Layout Grid
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['1', '2', '3'].map(_buildKey).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['4', '5', '6'].map(_buildKey).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['7', '8', '9'].map(_buildKey).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Logout fallback
                        IconButton(
                          onPressed: _isLoading
                              ? null
                              : () => ref.read(authProvider.notifier).logout(),
                          icon: const Icon(Icons.logout_outlined, size: 28, color: Color(0xFF64748B)),
                        ),
                        _buildKey('0'),
                        // Delete key
                        IconButton(
                          onPressed: _isLoading ? null : _onDelete,
                          icon: const Icon(Icons.backspace_outlined, size: 28, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC8102E)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
