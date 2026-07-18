import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  static const roles = [
    {'key': 'tenant', 'label': 'Tenant', 'blurb': 'Find a house and pay rent'},
    {'key': 'landlord', 'label': 'Landlord', 'blurb': 'List properties, track rent'},
    {'key': 'service_provider', 'label': 'Service Provider', 'blurb': 'Plumber, electrician, mover…'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join AltavasHomes as…',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ...roles.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      title: Text(r['label']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      subtitle: Text(r['blurb']!),
                      onTap: () => context.push('/signup', extra: r['key']),
                    ),
                  )),
              TextButton(
                onPressed: () => context.go('/signin'),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
