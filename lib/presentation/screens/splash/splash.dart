part of 'splash_imports.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;
  Timer? _safetyTimer;

  void _navigate(String route) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _safetyTimer?.cancel();
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthCheckRequested());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Safety fallback: ensures splash screen NEVER stays stuck
    _safetyTimer = Timer(const Duration(milliseconds: 2800), () async {
      if (_navigated || !mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _navigate('/home');
      } else if (authState is AuthUnauthenticated) {
        _navigate('/login');
      } else {
        try {
          final con = await Connectivity().checkConnectivity();
          final isOffline =
              con.isEmpty || con.every((r) => r == ConnectivityResult.none);
          if (isOffline) {
            if (mounted) {
              context.read<AuthBloc>().add(AuthGuestLoginRequested());
            }
            _navigate('/home');
          } else {
            _navigate('/login');
          }
        } catch (_) {
          _navigate('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _navigate('/home');
        } else if (state is AuthUnauthenticated) {
          _navigate('/login');
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF5A6858), // Slate moss top matching image.png center screen
                Color(0xFF384337), // Botanical obsidian deep green
                Color(0xFF1E261D), // Obsidian baseline
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative ambient glow circles
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Content matching image.png center mockup
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // Next-Gen Finance Pill
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Next-Gen Finance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Large Display Headline: Modern Tools for Modern Finance
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Modern Tools\nfor Modern\nFinance',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Center Hero Visual: Floating Obsidian Card
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Transform.rotate(
                            angle: -0.16,
                            child: Container(
                              width: 220,
                              height: 140,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161B16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 36,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // EMV Chip
                                      Container(
                                        width: 28,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                      const Icon(
                                        CupertinoIcons.wifi,
                                        color: Colors.white54,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Sajilo Khata',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/sajilo_khata_logo.png',
                                        width: 22,
                                        height: 22,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Bottom "Learn More / Continue" Action Pill matching image.png
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Spacer(),
                              Text(
                                'Learn More',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF191C1A),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF191C1A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.arrow_right,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
