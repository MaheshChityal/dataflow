import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  void _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    final success = await context.read<AuthProvider>().login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );
    setState(() => _loading = false);

    if (mounted && success) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (mounted) {
      final error = context.read<AuthProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Login failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ──
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF004C8F), Color(0xFF0066CC)],
                  ),
                  boxShadow: [BoxShadow(color: const Color(0xFF004C8F).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Center(
                  child: Text('H', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'DM Sans')),
                ),
              ),
              const SizedBox(height: 20),
              const Text('HDFC Pipeline Builder', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text, fontFamily: 'DM Sans')),
              const SizedBox(height: 4),
              const Text('Data Configuration Platform', style: TextStyle(fontSize: 13, color: AppColors.textDim)),
              const SizedBox(height: 36),

              // ── Login card ──
              Container(
                width: 380,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 4),
                    const Text('Enter your credentials to continue', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                    const SizedBox(height: 24),

                    // Username
                    const Text('Username', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameCtrl,
                      style: const TextStyle(color: AppColors.text, fontSize: 13),
                      decoration: _inputDecor(Icons.person_outline, 'Enter username'),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    const Text('Password', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: AppColors.text, fontSize: 13),
                      onSubmitted: (_) => _submit(),
                      decoration: _inputDecor(Icons.lock_outline, 'Enter password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.textDim),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004C8F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('HDFC Bank Internal Tool · v1.0', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 18, color: AppColors.textDim),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF004C8F), width: 1.5)),
      filled: true,
      fillColor: AppColors.surface2,
    );
  }
}
