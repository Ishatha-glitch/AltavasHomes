import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  static const Color _primaryColor = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isWideScreen = width > 700;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.home_work_rounded,
                    size: 80,
                    color: _primaryColor,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Choose Your Role",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Select how you'll use AltavasHomes.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  isWideScreen
                      ? Row(
                          children: const [
                            Expanded(
                              child: _RoleCard(
                                title: "Tenant",
                                subtitle:
                                    "Find houses, pay rent, download receipts and request maintenance.",
                                icon: Icons.apartment,
                                color: Colors.blue,
                                role: "tenant",
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: _RoleCard(
                                title: "Landlord",
                                subtitle:
                                    "Manage properties, tenants and monitor rent payments.",
                                icon: Icons.business,
                                color: Colors.green,
                                role: "landlord",
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: _RoleCard(
                                title: "Service Provider",
                                subtitle:
                                    "Receive maintenance jobs and grow your business.",
                                icon: Icons.handyman,
                                color: Colors.orange,
                                role: "service_provider",
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: const [
                            _RoleCard(
                              title: "Tenant",
                              subtitle:
                                  "Find houses, pay rent, download receipts and request maintenance.",
                              icon: Icons.apartment,
                              color: Colors.blue,
                              role: "tenant",
                            ),
                            SizedBox(height: 18),
                            _RoleCard(
                              title: "Landlord",
                              subtitle:
                                  "Manage properties, tenants and monitor rent payments.",
                              icon: Icons.business,
                              color: Colors.green,
                              role: "landlord",
                            ),
                            SizedBox(height: 18),
                            _RoleCard(
                              title: "Service Provider",
                              subtitle:
                                  "Receive maintenance jobs and grow your business.",
                              icon: Icons.handyman,
                              color: Colors.orange,
                              role: "service_provider",
                            ),
                          ],
                        ),

                  const SizedBox(height: 35),

                  TextButton(
                    onPressed: () {
                      context.go('/signin');
                    },
                    child: const Text(
                      "Already have an account? Sign In",
                    ),
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String role;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push(
            '/signup',
            extra: role,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: color.withOpacity(.12),
                child: Icon(
                  icon,
                  color: color,
                  size: 34,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.push(
                      '/signup',
                      extra: role,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
