import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../sms/screens/sms_settings_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../../../main.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmail = user.email ?? user.phoneNumber ?? 'No email';
      final prefs = await SharedPreferences.getInstance();
      _nameController.text =
          prefs.getString('userName') ?? user.displayName ?? '';
      _currency = prefs.getString('currency') ?? 'NPR';
      try {
        final data = await FirebaseService.instance.getProfile();
        if (data != null) {
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
    }
    if (mounted) {
      setState(() => _isLoading = false);
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

    try {
      await FirebaseService.instance.saveProfile(name, _currency);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(onPressed: _saveProfile, child: const Text('Save'))
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildProfileForm(),
                const SizedBox(height: 24),
                _buildSettings(),
                const SizedBox(height: 24),
                _buildAccountSection(),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = _nameController.text.isNotEmpty
        ? _nameController.text
              .trim()
              .split(' ')
              .take(2)
              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
              .join()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: AppTheme.signatureGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.onPrimary.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _nameController.text.isEmpty
                ? 'Set your name'
                : _nameController.text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Info',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            enabled: _isEditing,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.email_outlined,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            title: Text(_userEmail ?? 'Not available'),
            subtitle: const Text('Email address'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.currency_exchange_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            title: const Text('Currency'),
            trailing: DropdownButton<String>(
              value: _currency,
              underline: const SizedBox.shrink(),
              onChanged: _isEditing
                  ? (value) {
                      if (value != null) setState(() => _currency = value);
                    }
                  : null,
              items: const [
                DropdownMenuItem(value: 'NPR', child: Text('NPR')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
              ],
            ),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sms_outlined,
                color: AppTheme.secondary,
                size: 18,
              ),
            ),
            title: const Text('SMS Settings'),
            subtitle: const Text('Auto-log expenses from SMS'),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SmsSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sync_rounded,
                color: AppTheme.secondary,
                size: 18,
              ),
            ),
            title: const Text('Sync Data'),
            subtitle: const Text('Fetch all data from Firestore'),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
            ),
            onTap: () => _syncData(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 1.5),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncData(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing data from Firestore...')),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(AuthSignOutRequested());
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
