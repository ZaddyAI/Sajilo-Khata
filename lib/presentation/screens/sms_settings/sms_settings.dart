part of 'sms_settings_imports.dart';

class SmsSettingsScreen extends StatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  State<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends State<SmsSettingsScreen> {
  FirebaseFirestoreDataSource? _firestore;
  bool _manualOnly = true;
  bool _isSyncing = false;
  bool _isLoading = true;
  List<String> _selectedGroups = [];
  List<String> _deviceSenders = [];
  bool _isScanning = false;

  FirebaseFirestoreDataSource get _db =>
      _firestore ??= context.read<FirebaseFirestoreDataSource>();

  /// Guests (and offline starts) have no Firebase session - their SMS settings
  /// live in SharedPreferences instead of Firestore.
  bool get _isSignedIn {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    var enabled = prefs.getBool('smsAutoTrack') ?? true;
    var groups = prefs.getStringList('smsGroups') ?? <String>[];

    if (_isSignedIn) {
      try {
        enabled = await _db.getSmsAutoTrack().timeout(
          const Duration(seconds: 5),
        );
        final cloudGroups = await _db.getSelectedSmsGroups().timeout(
          const Duration(seconds: 5),
        );
        // Cloud is the source of truth when signed in, but keep any senders
        // selected while browsing as a guest.
        groups = cloudGroups.isNotEmpty ? cloudGroups : groups;
      } catch (_) {
        // Offline / timed out - fall back to the local values read above.
      }
    }

    // Always make the parser aware of the selection (also for guests, whose
    // selection would otherwise never reach SmsService).
    SmsService().updateSelectedGroups(groups);

    try {
      await _scanSenders();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _manualOnly = !enabled;
        _selectedGroups = groups;
        _isLoading = false;
      });
    }
  }

  Future<void> _scanSenders() async {
    setState(() => _isScanning = true);
    try {
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 1000,
      );
      final senders = <String>{};
      for (final msg in messages) {
        if (msg.address.isNotEmpty) {
          senders.add(msg.address);
        }
      }
      if (mounted) {
        setState(() {
          _deviceSenders = senders.toList()..sort();
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
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
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.back,
                              size: 22,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Settings',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SMS Auto-Tracking',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.onSurface,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildSyncModeCard(context),
          const SizedBox(height: 16),
          _buildStatusCard(),
          if (_isSyncing) ...[
            const SizedBox(height: 24),
            const Center(child: CupertinoActivityIndicator(radius: 14)),
          ],
          if (!_manualOnly && !_isSyncing) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _requestSmsPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(CupertinoIcons.shield_fill, size: 18),
                label: Text(
                  'Grant SMS Permission',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.dashboardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-Device SMS Parsing',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Bank SMS are parsed privately on your device. Messages are never transmitted to external servers.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncModeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.iosCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRACKING MODE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _setMode(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _manualOnly ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        boxShadow: _manualOnly
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Manual Entry',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: _manualOnly
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _manualOnly
                                ? AppTheme.onSurface
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _setMode(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_manualOnly ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        boxShadow: !_manualOnly
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Automatic Sync',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: !_manualOnly
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: !_manualOnly
                                ? AppTheme.onSurface
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_manualOnly) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Select Bank Senders',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isScanning ? null : _scanSenders,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isScanning)
                        const CupertinoActivityIndicator(radius: 8)
                      else
                        const Icon(
                          CupertinoIcons.arrow_clockwise,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _isScanning ? 'Scanning...' : 'Scan Device',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_deviceSenders.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info,
                      size: 18,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No SMS senders found yet. Tap "Scan Device" above.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _deviceSenders.map((sender) {
                  final isSelected = _selectedGroups.contains(sender);
                  return GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final newGroups = List<String>.from(_selectedGroups);
                      if (!isSelected) {
                        newGroups.add(sender);
                      } else {
                        newGroups.remove(sender);
                      }
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('smsGroups', newGroups);
                      try {
                        await _db.setSelectedSmsGroups(newGroups);
                      } catch (_) {
                        // Offline / guest: local preference already saved.
                      }
                      SmsService().updateSelectedGroups(newGroups);
                      setState(() => _selectedGroups = newGroups);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.mint : Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.outlineVariant,
                          width: isSelected ? 1.4 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 13,
                              color: AppTheme.primaryDark,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            sender.length > 14
                                ? '${sender.substring(0, 14)}...'
                                : sender,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryDark
                                  : AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (_selectedGroups.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Divider(height: 0.8, color: AppTheme.outlineVariant),
              const SizedBox(height: 14),
              Text(
                'Historical Sync Periods',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _importChip(
                    icon: CupertinoIcons.calendar_today,
                    label: 'Today',
                    onTap: _isSyncing ? null : () => _syncSms(0),
                  ),
                  _importChip(
                    icon: CupertinoIcons.calendar,
                    label: '7 Days',
                    onTap: _isSyncing ? null : () => _syncSms(7),
                  ),
                  _importChip(
                    icon: CupertinoIcons.calendar,
                    label: '30 Days',
                    onTap: _isSyncing ? null : () => _syncSms(30),
                  ),
                  _importChip(
                    icon: CupertinoIcons.ellipsis,
                    label: 'Custom Date',
                    onTap: _isSyncing ? null : () => _selectCustomDate(context),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _importChip({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(color: AppTheme.outlineVariant, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    IconData icon;
    String title;
    String subtitle;
    Color bgColor;
    Color iconColor;

    if (_manualOnly) {
      icon = CupertinoIcons.hand_draw;
      title = 'Manual Mode Active';
      subtitle =
          'You have complete control. Add transactions using the + button.';
      bgColor = AppTheme.surfaceContainerLow;
      iconColor = AppTheme.primary;
    } else {
      icon = CupertinoIcons.checkmark_shield_fill;
      title = 'Automatic Tracking Active';
      subtitle =
          'SMS permission granted. Transaction messages parsed locally on-device.';
      bgColor = AppTheme.mint;
      iconColor = AppTheme.primaryDark;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.iosCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setMode(bool manual) async {
    HapticFeedback.selectionClick();
    if (manual == false) {
      final granted = await _requestSmsPermission();
      if (!granted) return;
    }
    final enabled = !manual;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smsAutoTrack', enabled);
    try {
      await _db.setSmsAutoTrack(enabled);
    } catch (_) {
      // Offline / guest: the local preference is what SmsService reads.
    }
    setState(() => _manualOnly = manual);
  }

  Future<bool> _requestSmsPermission() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;
    final result = await Permission.sms.request();
    if (result.isGranted) return true;
    if (result.isPermanentlyDenied && mounted) {
      showSmoothDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Enable SMS permission in your device system settings to parse bank transactions.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _syncSmsByDate(picked);
    }
  }

  Future<void> _syncSmsByDate(DateTime fromDate) async {
    if (_selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one sender')),
      );
      return;
    }
    setState(() => _isSyncing = true);
    await _doSync(fromDate);
  }

  Future<void> _syncSms(int daysAgo) async {
    if (_selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one sender')),
      );
      return;
    }
    setState(() => _isSyncing = true);
    final now = DateTime.now();
    // "Today" must mean from the start of the day, not from this exact moment.
    final fromDate = daysAgo <= 0
        ? DateTime(now.year, now.month, now.day)
        : now.subtract(Duration(days: daysAgo));
    await _doSync(fromDate);
  }

  Future<void> _doSync(DateTime fromDate) async {
    try {
      final allMessages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 1000,
      );
      final fromMs = fromDate.millisecondsSinceEpoch;
      final messages = allMessages.where((msg) {
        return msg.date >= fromMs;
      }).toList();
      final selectedLower = _selectedGroups.map((g) => g.toLowerCase()).toSet();
      final filtered = messages.where((msg) {
        return selectedLower.any((g) => msg.address.toLowerCase().contains(g));
      }).toList();
      int imported = 0;
      for (final msg in filtered) {
        final success = await SmsService().importSmsWithCheck(
          msg.address,
          msg.body,
        );
        if (success) imported++;
      }
      // Push the freshly imported transactions into the UI immediately instead
      // of waiting for a manual pull-to-refresh (guest sessions have no
      // Firestore stream to trigger an update).
      if (mounted) {
        context.read<TransactionBloc>().add(TransactionLoadRequested());
      }
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $imported transactions'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
