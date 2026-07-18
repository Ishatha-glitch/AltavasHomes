import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';

import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/auth/sign_up_screen.dart';

import 'screens/tenant/tenant_dashboard.dart';
import 'screens/tenant/property_list_screen.dart';
import 'screens/tenant/property_detail_screen.dart';

import 'screens/landlord/landlord_dashboard.dart';
import 'screens/landlord/add_property_screen.dart';

import 'screens/service_provider/service_provider_dashboard.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/signin',
    redirect: (context, state) {
      final loggedIn = auth.session != null && auth.profile != null;
      final loggingIn = ['/signin', '/role-select', '/signup'].contains(state.matchedLocation);

      if (auth.loading) return null; // wait for splash
      if (!loggedIn && !loggingIn) return '/signin';
      if (loggedIn && loggingIn) {
        switch (auth.role) {
          case 'tenant':
            return '/tenant';
          case 'landlord':
            return '/landlord';
          case 'service_provider':
            return '/provider';
          default:
            return '/signin';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignUpScreen(role: state.extra as String? ?? 'tenant'),
      ),

      // Tenant
      GoRoute(path: '/tenant', builder: (_, __) => const TenantDashboard()),
      GoRoute(path: '/tenant/browse', builder: (_, __) => const PropertyListScreen()),
      GoRoute(
        path: '/tenant/property',
        builder: (context, state) => PropertyDetailScreen(property: state.extra as Map<String, dynamic>),
      ),

      // Landlord
      GoRoute(path: '/landlord', builder: (_, __) => const LandlordDashboard()),
      GoRoute(path: '/landlord/add-property', builder: (_, __) => const AddPropertyScreen()),

      // Service provider
      GoRoute(path: '/provider', builder: (_, __) => const ServiceProviderDashboard()),
    ],
  );
}
