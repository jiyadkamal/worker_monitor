import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).register(
        _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);

    if (mounted) {
      final state = ref.read(authProvider);
      if (state.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    // ── Auth Navigation Listener ─────────────────────
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && mounted) {
        // Pop back to the AuthGate which will now show HomeScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Join the Network'),
        leading: BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // ── Background Gradient ──────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  cs.secondary,
                  cs.primary,
                  cs.primary.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          
          // ── Glass-like Overlay ───────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  color: Colors.white.withValues(alpha: 0.9),
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Icon ──────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.secondary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.badge_rounded,
                              size: 48, color: cs.secondary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Create Account',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start monitoring safety today',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 40),

                        // ── Form ─────────────────────────────
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (!v.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length < 6) return 'Min 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 56,
                                child: FilledButton(
                                  onPressed: authState.status == AuthStatus.loading
                                      ? null
                                      : _submit,
                                  child: authState.status == AuthStatus.loading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Create Account'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
