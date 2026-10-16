part of 'profile_imports.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  String? _userEmail;
  String _currency = 'NPR';
  bool _isLoading = true;
  bool _isEditing = false;
  bool _smsAutoTrack = true;
  bool _isManualSyncing = false;
  String? _lastSyncTimeFormatted;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLastSyncTime();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'NPR';

    if (user != null) {
      _userEmail = user.email ?? user.phoneNumber ?? 'No email';
      _nameController.text =
          prefs.getString('userName') ?? user.displayName ?? '';
      try {
        final result = await context.read<AuthRepository>().getProfile();
        if (result.data != null) {
          final data = result.data!;
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _nameController.text = data['name'].toString();
            await prefs.setString('userName', data['name'].toString());
          }
          if (data['currency'] != null) {
            _currency = data['currency'].toString();
            CurrencyHelper.setCurrency(_currency);
            await prefs.setString('currency', _currency);
          }
        }
      } catch (_) {}
    } else {
      _userEmail = 'Offline Guest Account';
      _nameController.text = prefs.getString('userName') ?? 'Guest User';
    }

    // Reflect the real SMS auto-tracking state instead of the default ON.
    if (user != null) {
      try {
        _smsAutoTrack = await context
            .read<FirebaseFirestoreDataSource>()
            .getSmsAutoTrack()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        _smsAutoTrack = prefs.getBool('smsAutoTrack') ?? true;
      }
    } else {
      _smsAutoTrack = prefs.getBool('smsAutoTrack') ?? true;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMillis = prefs.getInt('last_cloud_sync_time');
    if (lastSyncMillis != null && mounted) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
      setState(() {
        _lastSyncTimeFormatted = _formatSyncTime(dt);
      });
    }
  }

  String _formatSyncTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1 && now.day == dt.day) {
      return 'Today at ${DateFormat('h:mm a').format(dt)}';
    } else if (diff.inDays < 2) {
      return 'Yesterday at ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }

  Future<void> _performCloudSync() async {
    if (_isManualSyncing) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sign in to sync your data with the cloud.'),
          action: SnackBarAction(
            label: 'Sign In',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _isManualSyncing = true);

    try {
      final syncRepo = context.read<SyncRepository>();
      final isOnline = await syncRepo.isOnline;
      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No internet connection. Changes will sync once back online.',
              ),
              backgroundColor: AppTheme.expense,
            ),
          );
        }
        return;
      }

      final result = await syncRepo.syncAll();

      if (mounted) {
        if (result.isSuccess) {
          final now = DateTime.now();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            'last_cloud_sync_time',
            now.millisecondsSinceEpoch,
          );

          // Refresh Blocs so all screens update immediately with pulled/synced data
          context.read<TransactionBloc>().add(TransactionLoadRequested());
          context.read<GoalBloc>().add(GoalLoadRequested());

          setState(() {
            _lastSyncTimeFormatted = 'Just now';
          });

          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(
                    CupertinoIcons.checkmark_alt_circle_fill,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text('Cloud sync complete! All data up to date.'),
                ],
              ),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync error: ${result.error ?? "Failed to sync"}'),
              backgroundColor: AppTheme.expense,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualSyncing = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
        return;
      }
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await context.read<AuthRepository>().saveProfile(name, _currency);
      } catch (e) {
        debugPrint('[Profile] Error saving profile to cloud: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('currency', _currency);
    final currencyChanged = CurrencyHelper.currency != _currency;
    context.read<CurrencyNotifier>().setCurrency(_currency);
    setState(() => _isEditing = false);
    if (mounted) {
      if (currencyChanged) {
        AppRestarter.restart();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  Future<void> _saveSmsSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smsAutoTrack', enabled);
    // Keep the cloud copy in sync so SmsService (which reads Firestore for
    // signed-in users) and the SMS settings screen honour this toggle.
    try {
      await context.read<FirebaseFirestoreDataSource>().setSmsAutoTrack(
        enabled,
      );
    } catch (_) {
      // Offline / guest: local preference already saved.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.88),
                border: const Border(
                  bottom: BorderSide(color: Color(0x12000000), width: 0.5),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Account & Settings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (_isEditing)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _saveProfile,
                          child: Text(
                            'Done',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeroCard(),
                  if (FirebaseAuth.instance.currentUser == null) ...[
                    const SizedBox(height: 14),
                    _buildGuestConnectCard(),
                  ],
                  const SizedBox(height: 22),

                  _buildSectionHeader('DATA & CLOUD SYNC'),
                  _buildCloudSyncGroup(),
                  const SizedBox(height: 22),

                  _buildSectionHeader('PREFERENCES'),
                  _buildPreferencesGroup(),
                  const SizedBox(height: 22),

                  _buildSectionHeader('AUTOMATION'),
                  _buildAutomationGroup(),
                  const SizedBox(height: 22),

                  _buildSectionHeader('SUPPORTED SMS PARSERS'),
                  _buildBankGroup(),
                  const SizedBox(height: 22),

                  _buildSectionHeader('LEGAL & POLICIES'),
                  _buildLegalGroup(),
                  const SizedBox(height: 22),

                  _buildSectionHeader('ACCOUNT'),
                  _buildAccountGroup(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard() {
    final initials = _nameController.text.isNotEmpty
        ? _nameController.text
              .trim()
              .split(' ')
              .take(2)
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
              .join()
        : 'U';

    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.mint,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isEditing = !_isEditing);
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _isEditing
                          ? CupertinoIcons.checkmark
                          : CupertinoIcons.pencil,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CupertinoTextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                placeholder: 'Enter your name',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            )
          else
            Text(
              _nameController.text.isEmpty
                  ? 'Set Your Name'
                  : _nameController.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            _userEmail ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isManualSyncing ? null : _performCloudSync,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isGuest ? const Color(0xFFFFF7E6) : AppTheme.mint,
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                border: Border.all(
                  color: isGuest
                      ? const Color(0xFFFFE099)
                      : AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isManualSyncing) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CupertinoActivityIndicator(radius: 6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Syncing...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      isGuest
                          ? CupertinoIcons.bolt_slash
                          : CupertinoIcons.cloud_upload,
                      size: 12,
                      color: isGuest
                          ? const Color(0xFFB78103)
                          : AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isGuest
                          ? 'Guest Mode (Tap to Sign In)'
                          : (_lastSyncTimeFormatted != null
                                ? 'Synced ($_lastSyncTimeFormatted)'
                                : 'Cloud Synchronized • Tap to Sync'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isGuest
                            ? const Color(0xFFB78103)
                            : AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSyncGroup() {
    final isGuest = FirebaseAuth.instance.currentUser == null;
    final syncRepo = context.read<SyncRepository>();
    final pendingCount = syncRepo.pendingSyncCount;

    String subtitleText;
    if (_isManualSyncing) {
      subtitleText = 'Syncing transactions & goals with cloud...';
    } else if (isGuest) {
      subtitleText = 'Local guest storage only. Sign in to backup.';
    } else if (pendingCount > 0) {
      subtitleText = '$pendingCount pending change(s) to upload';
    } else if (_lastSyncTimeFormatted != null) {
      subtitleText = 'Last synced: $_lastSyncTimeFormatted';
    } else {
      subtitleText = 'Upload local changes & fetch latest from cloud';
    }

    return Container(
      decoration: AppTheme.iosCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: _isManualSyncing ? null : _performCloudSync,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildGroupIcon(
                  CupertinoIcons.cloud_upload,
                  _isManualSyncing
                      ? AppTheme.primary
                      : isGuest
                      ? const Color(0xFFB78103)
                      : AppTheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sync with Cloud',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          if (pendingCount > 0 && !isGuest) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF2D6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$pendingCount pending',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB78103),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (_isManualSyncing)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CupertinoActivityIndicator(radius: 10),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isGuest
                          ? AppTheme.surfaceContainerLow
                          : AppTheme.mint,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      border: Border.all(
                        color: isGuest
                            ? AppTheme.outlineVariant
                            : AppTheme.primary.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_2_circlepath,
                          size: 12,
                          color: isGuest
                              ? AppTheme.onSurfaceVariant
                              : AppTheme.primaryDark,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isGuest ? 'Sign In' : 'Sync Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isGuest
                                ? AppTheme.onSurfaceVariant
                                : AppTheme.primaryDark,
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
    );
  }

  Widget _buildPreferencesGroup() {
    return Container(
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          // Currency Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildGroupIcon(
                  CupertinoIcons.money_dollar_circle,
                  AppTheme.income,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Currency',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'Convert figures between NPR and USD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: ['NPR', 'USD'].map((c) {
                    final selected = _currency == c;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _currency = c);
                        _saveProfile();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        child: Text(
                          c,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationGroup() {
    return Container(
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildGroupIcon(CupertinoIcons.text_bubble, AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS Auto-Tracking',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'Automatically convert bank SMS to ledger entries',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _smsAutoTrack,
                  activeTrackColor: AppTheme.primary,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _smsAutoTrack = v);
                    _saveSmsSetting(v);
                  },
                ),
              ],
            ),
          ),
          const Divider(
            height: 0.8,
            indent: 52,
            color: AppTheme.outlineVariant,
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pushNamed(context, '/sms_settings');
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildGroupIcon(
                    CupertinoIcons.slider_horizontal_3,
                    AppTheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SMS Filters & Sender Management',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: AppTheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankGroup() {
    final parsers = [
      ('Nabil Bank Limited', 'NABIL'),
      ('Global IME Bank', 'GIME'),
      ('NIC Asia Bank', 'NICASIA'),
      ('Nepal Investment Mega Bank', 'NIMB'),
      ('Agriculture Development Bank', 'ADBL'),
      ('Laxmi Sunrise Bank', 'LSL'),
    ];

    return Container(
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: parsers.asMap().entries.map((entry) {
          final isLast = entry.key == parsers.length - 1;
          final (bankName, code) = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bankName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Ready',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 0.8,
                  indent: 64,
                  color: AppTheme.outlineVariant,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountGroup() {
    final isGuest = FirebaseAuth.instance.currentUser == null;
    return Container(
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _confirmSignOut(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _buildGroupIcon(
                    isGuest
                        ? CupertinoIcons.arrow_right_square
                        : CupertinoIcons.square_arrow_right,
                    AppTheme.expense,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isGuest ? 'Exit Guest Session' : 'Sign Out',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.expense,
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: AppTheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestConnectCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mint,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.mintAccent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.cloud_upload,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloud Backup Available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  'Sign in to sync your ledger safely to cloud.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text(
              'Sign In',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupIcon(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildLegalGroup() {
    return Container(
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        children: [
          _buildLinkTile(
            icon: CupertinoIcons.shield_lefthalf_fill,
            color: AppTheme.primary,
            title: 'Privacy Policy',
            url: AppConstants.privacyPolicyUrl,
          ),
          const Divider(
            height: 0.8,
            indent: 52,
            color: AppTheme.outlineVariant,
          ),
          _buildLinkTile(
            icon: CupertinoIcons.doc_plaintext,
            color: AppTheme.secondary,
            title: 'Terms of Service',
            url: AppConstants.termsOfServiceUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color color,
    required String title,
    required String url,
  }) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            _buildGroupIcon(icon, color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.arrow_up_right,
              size: 15,
              color: AppTheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            child: Text(
              'v ${AppConstants.version}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crafted for modern personal finance tracking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final isGuest = FirebaseAuth.instance.currentUser == null;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(isGuest ? 'Exit Guest Session' : 'Sign Out'),
        message: Text(
          isGuest
              ? 'Are you sure you want to exit guest mode and return to login?'
              : 'Are you sure you want to sign out of your account?',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            child: Text(isGuest ? 'Exit Session' : 'Sign Out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
