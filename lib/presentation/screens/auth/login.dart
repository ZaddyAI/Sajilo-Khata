part of 'auth_imports.dart';

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
      begin: const Offset(0, 0.05),
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: AppTheme.surface,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // Atmospheric background blobs (matching Stitch bg-primary/5 and bg-secondary/5)
                Positioned(
                  top: -MediaQuery.of(context).size.height * 0.25,
                  left: -MediaQuery.of(context).size.width * 0.25,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -MediaQuery.of(context).size.height * 0.25,
                  right: -MediaQuery.of(context).size.width * 0.25,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondary.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Main centered content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Brand Identity Section
                                Column(
                                  children: [
                                    // Logo: w-20 h-20 bg-white rounded-xl border shadow
                                    Container(
                                      width: 80,
                                      height: 80,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.outlineVariant,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/sajilo_khata_logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Sajilo Khata',
                                      style: GoogleFonts.manrope(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your personal financial precision companion',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Login Card: bg-surface-container-lowest border rounded-xl shadow
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.outlineVariant,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: IgnorePointer(
                                    ignoring: isLoading,
                                    child: AnimatedOpacity(
                                      opacity: isLoading ? 0.6 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            // "Welcome Back" heading
                                            Text(
                                              'Welcome Back',
                                              style: GoogleFonts.manrope(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Sign in to access your ledger and goals',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                              ),
                                            ),

                                            const SizedBox(height: 24),

                                            if (state is AuthFailure)
                                              AuthErrorBanner(
                                                message: state.message,
                                              ),

                                            // EMAIL ADDRESS label + field
                                            Text(
                                              'EMAIL ADDRESS',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.8,
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: const InputDecoration(
                                                hintText: 'name@company.com',
                                                prefixIcon: Icon(
                                                  Icons.mail_outline_rounded,
                                                  size: 20,
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

                                            const SizedBox(height: 16),

                                            // PASSWORD label (with Forgot link)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'PASSWORD',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  child: Text(
                                                    'Forgot?',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) =>
                                                  _signIn(),
                                              decoration: InputDecoration(
                                                hintText: '••••••••',
                                                prefixIcon: const Icon(
                                                  Icons.lock_outline_rounded,
                                                  size: 20,
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
                                                    color: AppTheme
                                                        .onSurfaceVariant,
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

                                            const SizedBox(height: 24),

                                            // Sign In button
                                            AuthPrimaryButton(
                                              label: 'Sign In',
                                              loading: isLoading,
                                              onPressed: _signIn,
                                            ),

                                            const SizedBox(height: 16),

                                            // OR divider
                                            const AuthOrDivider(),

                                            const SizedBox(height: 16),

                                            // Continue with Google
                                            AuthGoogleButton(
                                              loading: isLoading,
                                              onPressed: () =>
                                                  context.read<AuthBloc>().add(
                                                    AuthGoogleSignInRequested(),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Bottom: Don't have an account? Sign Up
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: context.read<AuthBloc>(),
                                            child: const SignupScreen(),
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // "A Product of" footer
                                Opacity(
                                  opacity: 0.6,
                                  child: Column(
                                    children: [
                                      Text(
                                        'A PRODUCT OF',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2.0,
                                          color: AppTheme.outline,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/redpixellabs.png',
                                            width: 80,

                                            fit: BoxFit.contain,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Footer links
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _FooterLink(text: 'Privacy Policy'),
                                    const SizedBox(width: 16),
                                    _FooterLink(text: 'Terms of Service'),
                                    const SizedBox(width: 16),
                                    _FooterLink(text: 'Contact Support'),
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
              ],
            ),
          );
        },
      ),
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

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppTheme.outline,
      ),
    );
  }
}
