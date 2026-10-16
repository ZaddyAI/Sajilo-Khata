part of 'goals_imports.dart';

class GoalAchievedScreen extends StatefulWidget {
  final Goal goal;

  const GoalAchievedScreen({super.key, required this.goal});

  @override
  State<GoalAchievedScreen> createState() => _GoalAchievedScreenState();
}

class _GoalAchievedScreenState extends State<GoalAchievedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeTaken = widget.goal.deadlineAD.difference(widget.goal.createdAt);
    final monthsTaken = (timeTaken.inDays / 30).ceil().clamp(1, 120);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Target Reached',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Icon(
            CupertinoIcons.xmark,
            color: AppTheme.onSurface,
            size: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.8, color: AppTheme.outlineVariant),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          children: [
            // Celebration Visual
            _buildCelebrationVisual(),
            const SizedBox(height: 28),

            // Headline & Subheadline
            _buildHeadline(),
            const SizedBox(height: 28),

            // Details Inset Grouped Bento
            _buildDetailsCard(monthsTaken),
            const SizedBox(height: 20),

            // Social Proof pill
            _buildSocialProof(),
            const SizedBox(height: 32),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationVisual() {
    return SizedBox(
      height: 180,
      child: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(
                opacity: _fadeAnim.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main emoji squircle container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.goal.emoji,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                    // Trophy badge
                    Positioned(
                      bottom: -6,
                      right: -6,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.sparkles,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      children: [
        Text(
          'Target Conquered!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppTheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "You've successfully saved "),
              TextSpan(
                text:
                    '${CurrencyHelper.symbol}${CurrencyHelper.format(widget.goal.targetAmount)}',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const TextSpan(text: ' for your goal '),
              TextSpan(
                text: widget.goal.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(int monthsTaken) {
    return Row(
      children: [
        Expanded(
          child: _DetailCard(
            label: 'Total Saved',
            value:
                '${CurrencyHelper.symbol}${CurrencyHelper.format(widget.goal.targetAmount)}',
            valueColor: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DetailCard(
            label: 'Goal Target',
            value:
                '${CurrencyHelper.symbol}${CurrencyHelper.format(widget.goal.targetAmount)}',
            valueColor: AppTheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DetailCard(
            label: 'Time Taken',
            value: '$monthsTaken Mo',
            valueColor: AppTheme.mintAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.mint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppTheme.mintAccent.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.onSurface,
                ),
                children: const [
                  TextSpan(text: 'Outstanding discipline! You have funded '),
                  TextSpan(
                    text: '100% of your savings target',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' for this goal.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: CupertinoButton(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(24),
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.square_list,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Back to Goals',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: CupertinoButton(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const AddGoalScreen()),
              );
            },
            child: Text(
              'Create Another Goal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppTheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
