import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_widgets.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppTheme.background,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: const BoxDecoration(
                  gradient: AppTheme.signatureGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28, topPad + 20, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppTheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Welcome back.',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.onPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue tracking\nyour finances.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: AppTheme.onPrimary.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                top: MediaQuery.of(context).size.height * 0.32,
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
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (state is AuthFailure)
                                    AuthErrorBanner(message: state.message),

                                  AuthFieldLabel(label: 'Email address'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
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

                                  AuthFieldLabel(label: 'Password'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _signIn(),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
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
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppTheme.onSurfaceVariant,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  AuthPrimaryButton(
                                    label: 'Sign In',
                                    loading: isLoading,
                                    onPressed: _signIn,
                                  ),
                                  const SizedBox(height: 16),
                                  const AuthOrDivider(),
                                  const SizedBox(height: 16),
                                  AuthGoogleButton(
                                    loading: isLoading,
                                    onPressed: () =>
                                        context.read<AuthBloc>().add(
                                          AuthGoogleSignInRequested(),
                                        ),
                                  ),

                                  const SizedBox(height: 32),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account?",
                                        style: Theme.of(context)
                                            .textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BlocProvider.value(
                                                  value: context.read<AuthBloc>(),
                                                  child: const SignupScreen(),
                                                ),
                                          ),
                                        ),
                                        child: Text(
                                          'Sign up',
                                          style: Theme.of(context)
                                              .textTheme.bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.w700,
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

              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: AppTheme.primary.withValues(alpha: 0.9),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Signing in...',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
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
    );
  }

  void _signIn() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthEmailSignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }
}
