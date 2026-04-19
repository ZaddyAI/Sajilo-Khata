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
      // Scan ALL messages without date filter
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sms,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Auto-Track SMS',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select senders from your device messages to track transactions automatically.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Manual Entry Only'),
                    subtitle: const Text('Add transactions manually'),
                    value: _manualOnly,
                    onChanged: _isLoading
                        ? null
                        : (value) async {
                            if (value == false) {
                              final granted = await _requestSmsPermission();
                              if (!granted) return;
                            }
                            await _firebaseService.setSmsAutoTrack(!value);
                            setState(() => _manualOnly = value);
                          },
                  ),
                  if (!_manualOnly) ...[
                    const Divider(),
                    Row(
                      children: [
                        const Text(
                          'Select Senders',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                          onPressed: _isScanning ? null : _scanSenders,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_deviceSenders.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey[100],
                        child: const Row(
                          children: [
                            Icon(Icons.sms_outlined),
                            SizedBox(width: 12),
                            Text('No senders - tap Scan'),
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
                            ),
                            selected: isSelected,
                            onSelected: (selected) async {
                              final newGroups = List<String>.from(
                                _selectedGroups,
                              );
                              if (selected) {
                                newGroups.add(sender);
                              } else {
                                newGroups.remove(sender);
                              }
                              await _firebaseService.setSelectedSmsGroups(
                                newGroups,
                              );
                              SmsService().updateSelectedGroups(newGroups);
                              setState(() => _selectedGroups = newGroups);
                            },
                            selectedColor: AppTheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            checkmarkColor: AppTheme.primary,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    if (_selectedGroups.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Import from Selected',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.today, size: 18),
                            label: const Text('Today'),
                            onPressed: _isSyncing ? null : () => _syncSms(0),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.calendar_today, size: 18),
                            label: const Text('7 Days'),
                            onPressed: _isSyncing ? null : () => _syncSms(7),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.date_range, size: 18),
                            label: const Text('30 Days'),
                            onPressed: _isSyncing ? null : () => _syncSms(30),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.calendar_month, size: 18),
                            label: const Text('Custom'),
                            onPressed: _isSyncing
                                ? null
                                : () => _selectCustomDate(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_manualOnly)
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Manual mode: Add transactions using + on Dashboard',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_manualOnly)
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'SMS permission required. Your data stays on your device.',
                        style: TextStyle(color: Colors.amber[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_isSyncing) const Center(child: CircularProgressIndicator()),
          if (!_manualOnly && !_isSyncing)
            ElevatedButton.icon(
              onPressed: _requestSmsPermission,
              icon: const Icon(Icons.security),
              label: const Text('Grant SMS Permission'),
            ),
        ],
      ),
    );
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
