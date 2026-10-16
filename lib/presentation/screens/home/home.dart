part of 'home_imports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onSwitchTab: onTabTapped),
      const TransactionListScreen(),
      const GoalsListScreen(),
      const ProfileScreen(),
    ];
  }

  void onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: _buildIosFloatingDock(context),
      ),
    );
  }

  /// Floating Dock Island with 4 tabs:
  /// - Tab 0: Cards / Dashboard
  /// - Tab 1: Ledger / Transactions
  /// - Tab 2: Targets / Goals
  /// - Tab 3: Menu / Profile
  /// Active tab has obsidian black circular pill with white icon.
  Widget _buildIosFloatingDock(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        22,
        0,
        22,
        bottomPadding > 0 ? bottomPadding : 16,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tab 0: Cards / Dashboard
                  _DockIconButton(
                    icon: _currentIndex == 0
                        ? CupertinoIcons.creditcard_fill
                        : CupertinoIcons.creditcard,
                    isActive: _currentIndex == 0,
                    onTap: () => onTabTapped(0),
                  ),

                  // Tab 1: Transfer / Ledger
                  _DockIconButton(
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    isActive: _currentIndex == 1,
                    onTap: () => onTabTapped(1),
                  ),

                  // Tab 2: Targets / Goals
                  _DockIconButton(
                    icon: _currentIndex == 2
                        ? CupertinoIcons.flag_fill
                        : CupertinoIcons.flag,
                    isActive: _currentIndex == 2,
                    onTap: () => onTabTapped(2),
                  ),

                  // Tab 3: Menu / Profile
                  _DockIconButton(
                    icon: _currentIndex == 3
                        ? CupertinoIcons.square_grid_2x2_fill
                        : CupertinoIcons.square_grid_2x2,
                    isActive: _currentIndex == 3,
                    onTap: () => onTabTapped(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DockIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF101510) : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: isActive ? 20 : 22,
            color: isActive ? Colors.white : const Color(0xFF8A9188),
          ),
        ),
      ),
    );
  }
}
