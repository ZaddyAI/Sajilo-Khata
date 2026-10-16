part of 'auth_imports.dart';

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
      begin: const Offset(0, 0.04),
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
            backgroundColor: AppTheme.background,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Positioned(
                  top: -100,
                  left: -80,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.mint.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  right: -80,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.mintAccent.withValues(alpha: 0.2),
                    ),
                  ),
                ),

                // Main content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top Back Button row
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minSize: 36,
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.outlineVariant,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.chevron_back,
                                            size: 16,
                                            color: AppTheme.onSurface,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Back',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Brand Header
                                Container(
                                  width: 64,
                                  height: 64,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AppTheme.outlineVariant,
                                      width: 0.8,
                                    ),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  child: Image.asset(
                                    'assets/sajilo_khata_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Create Account',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Begin your mindful financial journey today',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Form Card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(22),
                                  decoration: AppTheme.iosCardDecoration,
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
                                            if (state is AuthFailure)
                                              AuthErrorBanner(
                                                message: state.message,
                                              ),

                                            // FULL NAME
                                            Text(
                                              'FULL NAME',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _nameController,
                                              textCapitalization:
                                                  TextCapitalization.words,
                                              textInputAction:
                                                  TextInputAction.next,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.onSurface,
                                                  ),
                                              decoration: const InputDecoration(
                                                hintText: 'John Doe',
                                                prefixIcon: Icon(
                                                  CupertinoIcons.person,
                                                  size: 18,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                ),
                                              ),
                                              validator: (v) {
                                                if (v == null ||
                                                    v.trim().isEmpty) {
                                                  return 'Enter your full name';
                                                }
                                                return null;
                                              },
                                            ),

                                            const SizedBox(height: 14),

                                            // EMAIL ADDRESS
                                            Text(
                                              'EMAIL ADDRESS',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.onSurface,
                                                  ),
                                              decoration: const InputDecoration(
                                                hintText: 'name@company.com',
                                                prefixIcon: Icon(
                                                  CupertinoIcons.mail,
                                                  size: 18,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                ),
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return 'Enter your email';
                                                }
                                                if (!v.contains('@')) {
                                                  return 'Invalid email format';
                                                }
                                                return null;
                                              },
                                            ),

                                            const SizedBox(height: 14),

                                            // Passwords
                                            Text(
                                              'PASSWORD',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              textInputAction:
                                                  TextInputAction.next,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.onSurface,
                                                  ),
                                              decoration: InputDecoration(
                                                hintText: '••••••••',
                                                prefixIcon: const Icon(
                                                  CupertinoIcons.lock,
                                                  size: 18,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                ),
                                                suffixIcon: GestureDetector(
                                                  onTap: () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                                  child: Icon(
                                                    _obscurePassword
                                                        ? CupertinoIcons.eye
                                                        : CupertinoIcons
                                                              .eye_slash,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                              validator: (v) {
                                                if (v == null || v.isEmpty) {
                                                  return 'Create a password';
                                                }
                                                if (v.length < 6) {
                                                  return 'At least 6 characters';
                                                }
                                                return null;
                                              },
                                            ),

                                            const SizedBox(height: 14),

                                            Text(
                                              'CONFIRM PASSWORD',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.8,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _confirmController,
                                              obscureText: _obscureConfirm,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) =>
                                                  _signUp(),
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.onSurface,
                                                  ),
                                              decoration: InputDecoration(
                                                hintText: '••••••••',
                                                prefixIcon: const Icon(
                                                  CupertinoIcons.shield,
                                                  size: 18,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                ),
                                                suffixIcon: GestureDetector(
                                                  onTap: () => setState(
                                                    () => _obscureConfirm =
                                                        !_obscureConfirm,
                                                  ),
                                                  child: Icon(
                                                    _obscureConfirm
                                                        ? CupertinoIcons.eye
                                                        : CupertinoIcons
                                                              .eye_slash,
                                                    color: AppTheme
                                                        .onSurfaceVariant,
                                                    size: 18,
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

                                            const SizedBox(height: 22),

                                            // Sign Up button
                                            AuthPrimaryButton(
                                              label: 'Create Account',
                                              loading: isLoading,
                                              onPressed: _signUp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Already have an account?
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Sign In',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        final uri = Uri.parse(
                                          AppConstants.privacyPolicyUrl,
                                        );
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                      child: Text(
                                        'Privacy Policy',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '•',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppTheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final uri = Uri.parse(
                                          AppConstants.termsOfServiceUrl,
                                        );
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                      child: Text(
                                        'Terms of Service',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onSurfaceVariant,
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
              ],
            ),
          );
        },
      ),
    );
  }

  void _signUp() {
    HapticFeedback.lightImpact();
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
