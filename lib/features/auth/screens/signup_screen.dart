import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) Navigator.of(context).pop();
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: AppTheme.primary,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                if (!isLoading) ...[
                  // Decorative background circles
                  Positioned(
                    top: -40,
                    right: -80,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.onPrimary.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: -50,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.onPrimary.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ],

                Positioned.fill(
                  child: Column(
                    children: [
                      // ── Brand Section ───────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.fromLTRB(32, topPad + 32, 32, 32),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.onPrimary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.onPrimary.withValues(
                                      alpha: 0.15,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppTheme.onPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppTheme.onPrimary,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                                Text(
                                  'Join Sajilo Khata today',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.onPrimary.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Form Card ──────────────────────────────────────────
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32),
                                ),
                              ),
                              child: IgnorePointer(
                                ignoring: isLoading,
                                child: AnimatedOpacity(
                                  opacity: isLoading ? 0.5 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      28,
                                      36,
                                      28,
                                      32,
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          BlocBuilder<AuthBloc, AuthState>(
                                            builder: (context, state) {
                                              if (state is AuthFailure) {
                                                return AuthErrorBanner(
                                                  message: state.message,
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),

                                          // Name
                                          AuthFieldLabel(label: 'Full name'),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _nameController,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: const InputDecoration(
                                              hintText: 'John Doe',
                                              prefixIcon: Icon(
                                                Icons.person_outline_rounded,
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null ||
                                                  v.trim().isEmpty) {
                                                return 'Enter your name';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),

                                          // Email
                                          AuthFieldLabel(
                                            label: 'Email address',
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _emailController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: const InputDecoration(
                                              hintText: 'you@example.com',
                                              prefixIcon: Icon(
                                                Icons.mail_outline_rounded,
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Enter your email';
                                              }
                                              if (!v.contains('@')) {
                                                return 'Invalid email';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),

                                          // Password
                                          AuthFieldLabel(label: 'Password'),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscurePassword,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: InputDecoration(
                                              hintText: '••••••••',
                                              prefixIcon: const Icon(
                                                Icons.lock_outline_rounded,
                                              ),
                                              suffixIcon: GestureDetector(
                                                onTap: () => setState(
                                                  () => _obscurePassword =
                                                      !_obscurePassword,
                                                ),
                                                child: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                            .visibility_outlined
                                                      : Icons
                                                            .visibility_off_outlined,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Enter a password';
                                              }
                                              if (v.length < 6) {
                                                return 'At least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),

                                          // Confirm Password
                                          AuthFieldLabel(
                                            label: 'Confirm password',
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _confirmController,
                                            obscureText: _obscureConfirm,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) => _signUp(),
                                            decoration: InputDecoration(
                                              hintText: '••••••••',
                                              prefixIcon: const Icon(
                                                Icons.lock_outline_rounded,
                                              ),
                                              suffixIcon: GestureDetector(
                                                onTap: () => setState(
                                                  () => _obscureConfirm =
                                                      !_obscureConfirm,
                                                ),
                                                child: Icon(
                                                  _obscureConfirm
                                                      ? Icons
                                                            .visibility_outlined
                                                      : Icons
                                                            .visibility_off_outlined,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v !=
                                                  _passwordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 32),

                                          BlocBuilder<AuthBloc, AuthState>(
                                            builder: (context, state) {
                                              return AuthPrimaryButton(
                                                label: 'Create Account',
                                                loading: state is AuthLoading,
                                                onPressed: _signUp,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 24),

                                          Text(
                                            'By creating an account you agree to our\nTerms of Service & Privacy Policy.',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                  height: 1.5,
                                                ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Already have an account?',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: AppTheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  'Sign in',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: AppTheme.primary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.primary,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.onPrimary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppTheme.onPrimary.withValues(
                                    alpha: 0.15,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppTheme.onPrimary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthEmailSignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        ),
      );
    }
  }
}
