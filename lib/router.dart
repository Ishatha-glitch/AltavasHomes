import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';

import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

import 'screens/tenant/tenant_dashboard.dart';
import 'screens/tenant/property_list_screen.dart';
import 'screens/tenant/property_detail_screen.dart';
import 'screens/tenant/my_rental_screen.dart';
import 'screens/tenant/maintenance_requests_screen.dart';

import 'screens/landlord/landlord_property_details.dart';
import 'screens/landlord/landlord_dashboard.dart';
import 'screens/landlord/add_property_screen.dart';
import 'screens/landlord/pending_requests.dart';
import 'screens/landlord/edit_property_screen.dart';

import 'screens/service_provider/service_provider_dashboard.dart';

import 'screens/profile_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: auth,
    initialLocation: '/signin',

    redirect: (context, state) {
      if (auth.loading) {
        return null;
      }

      final bool loggedIn =
          auth.session != null && auth.profile != null;

      final bool isAuthRoute = [
        '/signin',
        '/signup',
        '/role-select',
        '/forgot-password',
      ].contains(state.matchedLocation);

      if (!loggedIn) {
        return isAuthRoute ? null : '/signin';
      }

      if (loggedIn && isAuthRoute) {
        switch (auth.role) {
          case 'tenant':
            return '/tenant';

          case 'landlord':
            return '/landlord';

          case 'service_provider':
            return '/provider';

          case 'admin':
            return '/admin';

          default:
            return '/signin';
        }
      }

      // Protect tenant routes
      if (state.matchedLocation.startsWith('/tenant') &&
          auth.role != 'tenant') {
        return _homeForRole(auth.role);
      }

      // Protect landlord routes
      if (state.matchedLocation.startsWith('/landlord') &&
          auth.role != 'landlord') {
        return _homeForRole(auth.role);
      }

      // Protect provider routes
      if (state.matchedLocation.startsWith('/provider') &&
          auth.role != 'service_provider') {
        return _homeForRole(auth.role);
      }

      return null;
    },

    routes: [

      //--------------------------
      // AUTH
      //--------------------------

      GoRoute(
        path: '/signin',
        builder: (_, __) => const SignInScreen(),
      ),

      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final role =
              (state.extra is String) ? state.extra as String : 'tenant';

          return SignUpScreen(role: role);
        },
      ),

      GoRoute(
        path: '/role-select',
        builder: (_, __) => const RoleSelectScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      //--------------------------
      // TENANT
      //--------------------------

      GoRoute(
        path: '/tenant',
        builder: (_, __) => const TenantDashboard(),
      ),

      GoRoute(
        path: '/tenant/browse',
        builder: (_, __) => const PropertyListScreen(),
      ),

      GoRoute(
        path: '/tenant/property',
        builder: (context, state) {

          if (state.extra == null ||
              state.extra is! Map<String, dynamic>) {
            return const NotFoundScreen();
          }

          return PropertyDetailScreen(
            property: state.extra as Map<String, dynamic>,
          );
        },
      ),
      GoRoute(
        path: '/tenant/my-rental',
        builder: (_, __) => const MyRentalScreen(),
      ),

      GoRoute(
        path: '/tenant/maintenance',
        builder: (_, __) => const MaintenanceRequestsScreen(),
      ),

      //--------------------------
      // LANDLORD
      //--------------------------

      GoRoute(
        path: '/landlord',
        builder: (_, __) => const LandlordDashboard(),
      ),

      GoRoute(
  path: '/landlord/add-property',
  builder: (_, __) => const AddPropertyScreen(),
),

     GoRoute(
  path: '/landlord/property',
  builder: (context, state) {
    if (state.extra == null ||
        state.extra is! Map<String, dynamic>) {
      return const NotFoundScreen();
    }

    return LandlordPropertyDetails(
      property: state.extra as Map<String, dynamic>,
    );
  },
),
      
      GoRoute(
        path: '/landlord/requests',
        builder: (_, __) => const PendingRequestsScreen(),
      ),

      //--------------------------
      // SERVICE PROVIDER
      //--------------------------

      GoRoute(
        path: '/provider',
        builder: (_, __) => const ServiceProviderDashboard(),
      ),

      //--------------------------
      // PROFILE
      //--------------------------

      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],

    errorBuilder: (context, state) =>
        const NotFoundScreen(),
  );
}

String _homeForRole(String? role) {
  switch (role) {
    case 'tenant':
      return '/tenant';

    case 'landlord':
      return '/landlord';

    case 'service_provider':
      return '/provider';

    case 'admin':
      return '/admin';

    default:
      return '/signin';
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 90,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                '404',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'The page you requested does not exist.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  context.go('/signin');
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
