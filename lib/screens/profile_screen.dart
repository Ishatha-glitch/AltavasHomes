import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../services/db.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _fullName = TextEditingController(text: _profile?['full_name'] ?? '');
  late final _phone = TextEditingController(text: _profile?['phone'] ?? '');
  late String _serviceCategory = _profile?['service_category'] ?? 'Plumber';
  bool _saving = false;

  static const categories = ['Plumber', 'Electrician', 'Mover', 'Cleaner', 'Painter', 'Other'];

  Map<String, dynamic>? get _profile => context.read<AuthProvider>().profile;

  Future<void> _save() async {
    if (_fullName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name can't be empty.")),
      );
      return;
    }
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final profileId = auth.profile?['id'];

    try {
      final updates = <String, dynamic>{
        'full_name': _fullName.text.trim(),
        'phone': _phone.text.trim(),
      };
      if (auth.role == 'service_provider') {
        updates['service_category'] = _serviceCategory;
      }

      await Db.client.from('profiles').update(updates).eq('id', profileId);
      await auth.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final roleLabel = (auth.role ?? '').replaceAll('_', ' ');

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              controller: TextEditingController(text: email),
              decoration: const InputDecoration(labelText: 'Email (contact support to change)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              controller: TextEditingController(text: roleLabel),
              decoration: const InputDecoration(labelText: 'Account type', border: OutlineInputBorder()),
            ),
            if (auth.role == 'service_provider') ...[
              const SizedBox(height: 16),
              const Text('Service category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categories.map((c) {
                  final selected = c == _serviceCategory;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _serviceCategory = c),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().signOut();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
