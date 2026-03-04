import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/kyc/kyc_verification_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/enhanced_home_screen.dart';
import '../screens/groups/groups_list_screen.dart';
import '../screens/groups/advanced_create_group_screen.dart';
import '../screens/groups/group_details_screen.dart';
import '../screens/groups/advanced_founder_dashboard.dart';
import '../screens/groups/add_member_screen.dart';
import '../screens/transactions/advanced_transactions_screen.dart';
import '../screens/loans/loans_list_screen.dart';
import '../screens/loans/advanced_loan_application_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/wallet/advanced_wallet_screen.dart';
import '../screens/analytics/analytics_dashboard_screen.dart';
import '../screens/guarantors/guarantor_management_screen.dart';
import '../screens/attendance/attendance_tracking_screen.dart';
import '../screens/chat/group_chat_screen.dart';
import '../screens/documents/documents_screen.dart';
import '../screens/referral/referral_screen.dart';
import '../screens/help/help_support_screen.dart';
import '../screens/biometric/biometric_setup_screen.dart';
import '../screens/payment_methods/payment_methods_screen.dart';
import '../screens/escrow/escrow_monitoring_screen.dart';
import '../../core/services/auth_service.dart';

final authStateProvider = StateProvider<bool>((ref) => false);

class AppRouter {
  static GoRouter router(WidgetRef ref) => GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = ref.read(authStateProvider);
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      
      if (!isAuth && !isGoingToAuth && state.matchedLocation != '/') {
        return '/login';
      }
      if (isAuth && isGoingToAuth) {
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
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/kyc',
        name: 'kyc',
        builder: (context, state) => const KYCVerificationScreen(),
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
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const EnhancedHomeScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/referral',
        name: 'referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/biometric-setup',
        name: 'biometric-setup',
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      GoRoute(
        path: '/payment-methods',
        name: 'payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/groups',
        name: 'groups',
        builder: (context, state) => const GroupsListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-group',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'] ?? '';
              return AdvancedCreateGroupScreen(userId: userId);
            },
          ),
          GoRoute(
            path: ':id',
            name: 'group-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return GroupDetailScreen(groupId: id);
            },
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'founder-dashboard',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final userId = state.uri.queryParameters['userId'] ?? '';
                  return AdvancedFounderDashboard(groupId: id, userId: userId);
                },
              ),
              GoRoute(
                path: 'add-member',
                name: 'add-member',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final userId = state.uri.queryParameters['userId'] ?? '';
                  return AddMemberScreen(groupId: id, userId: userId);
                },
              ),
              GoRoute(
                path: 'chat',
                name: 'group-chat',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final name = state.uri.queryParameters['name'] ?? 'Group Chat';
                  return GroupChatScreen(groupId: id, groupName: name);
                },
              ),
              GoRoute(
                path: 'escrow',
                name: 'group-escrow',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return EscrowMonitoringScreen(groupId: id);
                },
              ),
              GoRoute(
                path: 'meeting/:meetingId/attendance',
                name: 'meeting-attendance',
                builder: (context, state) {
                  final meetingId = state.pathParameters['meetingId']!;
                  final isOrganizer = state.uri.queryParameters['organizer'] == 'true';
                  return AttendanceTrackingScreen(meetingId: meetingId, isOrganizer: isOrganizer);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const AdvancedTransactionsScreen(),
      ),
      GoRoute(
        path: '/loans',
        name: 'loans',
        builder: (context, state) => const LoansListScreen(userId: ''),
        routes: [
          GoRoute(
            path: 'request',
            name: 'request-loan',
            builder: (context, state) {
              final groupId = state.uri.queryParameters['groupId'] ?? '';
              return AdvancedLoanApplicationScreen(groupId: groupId, userId: '');
            },
          ),
          GoRoute(
            path: ':loanId/guarantors',
            name: 'loan-guarantors',
            builder: (context, state) {
              final loanId = state.pathParameters['loanId']!;
              return GuarantorManagementScreen(loanId: loanId);
            },
          ),
        ],
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
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('404 - Paji ntiyabonetse', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Subira ahabanza'),
            ),
          ],
        ),
      ),
    ),
  );
}
