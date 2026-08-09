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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) Navigator.of(context).pop();
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            // Stitch: bg-surface (light page)
            backgroundColor: AppTheme.surface,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                // Atmospheric background blobs
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

                // Main content
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            children: [
                              // Mobile branding top (matching Stitch: lg:hidden)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.account_balance_rounded,
                                    color: AppTheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sajilo Khata',
                                    style: GoogleFonts.manrope(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // Heading
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: GoogleFonts.manrope(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Start managing your business records systematically.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Registration Card
                              Container(
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
                                    duration: const Duration(milliseconds: 200),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (state is AuthFailure)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: AuthErrorBanner(
                                                message: state.message,
                                              ),
                                            ),

                                          // FULL NAME
                                          _FieldLabel(label: 'FULL NAME'),
                                          const SizedBox(height: 6),
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
                                                size: 20,
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

                                          const SizedBox(height: 16),

                                          // EMAIL ADDRESS
                                          _FieldLabel(label: 'EMAIL ADDRESS'),
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

                                          // Password row (2 columns in Stitch)
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _FieldLabel(
                                                      label: 'PASSWORD',
                                                    ),
                                                    const SizedBox(height: 6),
                                                    TextFormField(
                                                      controller:
                                                          _passwordController,
                                                      obscureText:
                                                          _obscurePassword,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      decoration: InputDecoration(
                                                        hintText: '••••••••',
                                                        prefixIcon: const Icon(
                                                          Icons
                                                              .lock_outline_rounded,
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
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                      validator: (v) {
                                                        if (v == null ||
                                                            v.isEmpty) {
                                                          return 'Required';
                                                        }
                                                        if (v.length < 6) {
                                                          return 'Min 6 chars';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _FieldLabel(
                                                      label: 'CONFIRM',
                                                    ),
                                                    const SizedBox(height: 6),
                                                    TextFormField(
                                                      controller:
                                                          _confirmController,
                                                      obscureText:
                                                          _obscureConfirm,
                                                      textInputAction:
                                                          TextInputAction.done,
                                                      onFieldSubmitted: (_) =>
                                                          _signUp(),
                                                      decoration: InputDecoration(
                                                        hintText: '••••••••',
                                                        prefixIcon: const Icon(
                                                          Icons.shield_outlined,
                                                          size: 20,
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
                                                            color: AppTheme
                                                                .onSurfaceVariant,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                      validator: (v) {
                                                        if (v !=
                                                            _passwordController
                                                                .text) {
                                                          return 'No match';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 24),

                                          // Sign Up button
                                          AuthPrimaryButton(
                                            label: 'Sign Up',
                                            loading: isLoading,
                                            onPressed: _signUp,
                                          ),

                                          const SizedBox(height: 16),

                                          // OR divider
                                          const AuthOrDivider(),

                                          const SizedBox(height: 16),

                                          // Already have an account?
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Already have an account? ',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  'Login',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.primary,
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

                              const SizedBox(height: 24),

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

// Simple label widget matching Stitch's label-bold uppercase tracking-wider
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppTheme.onSurfaceVariant,
      ),
    );
  }
}
