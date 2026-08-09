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
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeTaken = widget.goal.deadlineAD.difference(widget.goal.createdAt);
    final monthsTaken = (timeTaken.inDays / 30).ceil();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Sajilo Khata',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.outlineVariant),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          children: [
            // Celebration Visual
            _buildCelebrationVisual(),
            const SizedBox(height: 32),

            // Headline & Subheadline
            _buildHeadline(),
            const SizedBox(height: 32),

            // Details Card (Bento-style layout)
            _buildDetailsCard(monthsTaken),
            const SizedBox(height: 24),

            // Social Proof/Impact
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
      height: 200,
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
                    // Main emoji container
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.goal.emoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                    // Trophy badge
                    Positioned(
                      bottom: -8,
                      right: -8,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppTheme.onPrimary,
                          size: 28,
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
          'Congratulations!',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 16,
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
              const TextSpan(text: ' for your '),
              TextSpan(
                text: widget.goal.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
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
            valueColor: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DetailCard(
            label: 'Target Amount',
            value:
                '${CurrencyHelper.symbol}${CurrencyHelper.format(widget.goal.targetAmount)}',
            valueColor: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DetailCard(
            label: 'Time Taken',
            value: '$monthsTaken Month${monthsTaken > 1 ? 's' : ''}',
            valueColor: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_rounded, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSecondaryContainer,
                ),
                children: [
                  const TextSpan(text: 'You are now in the '),
                  const TextSpan(
                    text: 'top 5% of savers',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' this month!'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/goals');
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                'View All Goals',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add_goal');
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Start New Goal',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.secondary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              color: AppTheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
