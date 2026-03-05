import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/navigation/main_navigation_screen.dart';
import '../screens/home/enhanced_home_screen.dart';
import '../screens/groups/groups_list_screen.dart';
import '../screens/groups/advanced_create_group_screen.dart';
import '../screens/groups/group_details_screen.dart';
import '../screens/wallet/advanced_wallet_screen.dart';
import '../screens/transactions/advanced_transactions_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../../core/services/secure_storage_service.dart';

final authStateProvider = StateProvider<bool>((ref) => false);

class AppRouter {
  static GoRouter router(WidgetRef ref) => GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isAuth = ref.read(authStateProvider);
      final isGoingToAuth = state.matchedLocation == '/welcome' || 
                           state.matchedLocation == '/login' || 
                           state.matchedLocation == '/register';
      
      // Check if we have a token stored
      final token = await SecureStorageService().getAuthToken();
      final hasToken = token != null;

      if (!isAuth && !hasToken && !isGoingToAuth && state.matchedLocation != '/') {
        return '/welcome';
      }
      
      if ((isAuth || hasToken) && isGoingToAuth) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main Shell with Navigation
      ShellRoute(
        builder: (context, state, child) => const MainNavigationScreen(),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const EnhancedHomeScreen(),
          ),
          GoRoute(
            path: '/groups',
            name: 'groups',
            builder: (context, state) => const GroupsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-group',
                builder: (context, state) => const AdvancedCreateGroupScreen(userId: ''),
              ),
              GoRoute(
                path: ':id',
                name: 'group-detail',
                builder: (context, state) => GroupDetailScreen(groupId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const AdvancedTransactionsScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const AdvancedWalletScreen(userId: ''),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
