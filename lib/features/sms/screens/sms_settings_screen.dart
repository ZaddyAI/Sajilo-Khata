import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/sms_service.dart';

class SmsSettingsScreen extends StatefulWidget {
  const SmsSettingsScreen({super.key});

  @override
  State<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends State<SmsSettingsScreen> {
  final _firebaseService = FirebaseService.instance;
  bool _manualOnly = true;
  bool _isSyncing = false;
  bool _isLoading = true;
  List<String> _selectedGroups = [];
  List<String> _deviceSenders = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await _firebaseService.getSmsAutoTrack();
      final groups = await _firebaseService.getSelectedSmsGroups();
      SmsService().updateSelectedGroups(groups);
      await _scanSenders();
      if (mounted) {
        setState(() {
          _manualOnly = !enabled;
          _selectedGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _manualOnly = true;
          _selectedGroups = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _scanSenders() async {
    setState(() => _isScanning = true);
    try {
      final messages = await Telephony.instance.getInboxSms(
        columns: [SmsColumn.ADDRESS],
      );
      final senders = <String>{};
      for (final msg in messages) {
        if (msg.address != null && msg.address!.isNotEmpty) {
          senders.add(msg.address!);
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
      appBar: AppBar(title: const Text('SMS Auto-Track')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildSyncModeCard(context),
          const SizedBox(height: 16),
          _buildStatusCard(),
          if (_isSyncing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          ],
          if (!_manualOnly && !_isSyncing) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _requestSmsPermission,
                icon: const Icon(Icons.security, size: 20),
                label: const Text('Grant SMS Permission'),
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
        gradient: AppTheme.signatureGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sms_rounded, color: AppTheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMS Auto-Track',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select senders from your device\nmessages to track transactions automatically.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.onPrimary.withValues(alpha: 0.7),
                    height: 1.4,
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
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: const Color(0xFFF0F2F1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Mode',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _setMode(true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _manualOnly
                            ? AppTheme.surfaceContainerLowest
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _manualOnly ? AppTheme.cardShadow : [],
                      ),
                      child: const Center(
                        child: Text(
                          'Manual',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_manualOnly
                            ? AppTheme.surfaceContainerLowest
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_manualOnly ? AppTheme.cardShadow : [],
                      ),
                      child: const Center(
                        child: Text(
                          'Automatic',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                  'Select Senders',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: _isScanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                  onPressed: _isScanning ? null : _scanSenders,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_deviceSenders.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sms_outlined,
                      size: 18,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'No senders found - tap Scan',
                      style: Theme.of(context).textTheme.bodySmall,
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
                  return FilterChip(
                    label: Text(
                      sender.length > 12
                          ? '${sender.substring(0, 12)}...'
                          : sender,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) async {
                      final newGroups = List<String>.from(_selectedGroups);
                      if (selected) {
                        newGroups.add(sender);
                      } else {
                        newGroups.remove(sender);
                      }
                      await _firebaseService.setSelectedSmsGroups(newGroups);
                      SmsService().updateSelectedGroups(newGroups);
                      setState(() => _selectedGroups = newGroups);
                    },
                    selectedColor: AppTheme.primary.withValues(alpha: 0.12),
                    checkmarkColor: AppTheme.primary,
                  );
                }).toList(),
              ),
            if (_selectedGroups.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Import from Selected',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _importChip(
                    icon: Icons.today_rounded,
                    label: 'Today',
                    onTap: _isSyncing ? null : () => _syncSms(0),
                  ),
                  _importChip(
                    icon: Icons.date_range_rounded,
                    label: '7 Days',
                    onTap: _isSyncing ? null : () => _syncSms(7),
                  ),
                  _importChip(
                    icon: Icons.calendar_month_rounded,
                    label: '30 Days',
                    onTap: _isSyncing ? null : () => _syncSms(30),
                  ),
                  _importChip(
                    icon: Icons.more_horiz_rounded,
                    label: 'Custom',
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
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.primary),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
      onPressed: onTap,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.06),
      side: const BorderSide(color: AppTheme.primary, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildStatusCard() {
    IconData icon;
    String title;
    String subtitle;
    Color bgColor;
    Color iconColor;

    if (_manualOnly) {
      icon = Icons.info_outline_rounded;
      title = 'Manual Mode';
      subtitle = 'Add transactions using + on Dashboard';
      bgColor = const Color(0xFFE2F0FF);
      iconColor = const Color(0xFF0057B3);
    } else {
      icon = Icons.security_rounded;
      title = 'Automatic Mode';
      subtitle = 'SMS permission required. Your data stays on your device.';
      bgColor = const Color(0xFFFFF4E0);
      iconColor = const Color(0xFFB8860B);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: iconColor.withValues(alpha: 0.8),
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
    if (manual == false) {
      final granted = await _requestSmsPermission();
      if (!granted) return;
    }
    await _firebaseService.setSmsAutoTrack(!manual);
    setState(() => _manualOnly = manual);
  }

  Future<bool> _requestSmsPermission() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;
    final result = await Permission.sms.request();
    if (result.isGranted) return true;
    if (result.isPermanentlyDenied && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('Enable SMS permission in settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Open Settings'),
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
    final fromDate = DateTime.now().subtract(Duration(days: daysAgo));
    await _doSync(fromDate);
  }

  Future<void> _doSync(DateTime fromDate) async {
    try {
      final messages = await Telephony.instance.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(
          SmsColumn.DATE,
        ).greaterThan(fromDate.millisecondsSinceEpoch.toString()),
      );
      final selectedLower = _selectedGroups.map((g) => g.toLowerCase()).toSet();
      final filtered = messages.where((msg) {
        final addr = msg.address?.toLowerCase() ?? '';
        return selectedLower.any((g) => addr.contains(g));
      }).toList();
      int imported = 0;
      for (final msg in filtered) {
        final success = await SmsService().importSmsWithCheck(
          msg.address ?? '',
          msg.body ?? '',
        );
        if (success) imported++;
      }
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported transactions')),
      );
    } catch (e) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
