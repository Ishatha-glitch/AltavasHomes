import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TenantDashboard extends StatelessWidget {
  const TenantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tenant Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Welcome",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          Card(
            child: ListTile(
              leading: const Icon(Icons.search),
              title: const Text("Browse Properties"),
              subtitle: const Text(
                "Find houses, apartments and hostels",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push("/tenant/browse");
              },
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text("My Rental"),
              subtitle: const Text(
                "View your current rental",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/tenant/my-rental');
              },
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.payments),
              title: const Text("Rent Payments"),
              subtitle: const Text(
                "Pay rent and view payment history",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/tenant/my-rental');
              },
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.build),
              title: const Text("Maintenance Requests"),
              subtitle: const Text(
                "Report maintenance issues",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/tenant/maintenance');
              },
            ),
          ),

        const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: const Text("Find a Service Provider"),
              subtitle: const Text("For tasks not related to the property"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/service-providers'),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text("Messages"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/messages'),
            ),
          ),  
        ],
      ),
    );
  }
}
