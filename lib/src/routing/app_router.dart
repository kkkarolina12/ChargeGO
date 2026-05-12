import 'package:chargego/src/features/home/presentation/home_screen.dart';
import 'package:chargego/src/features/map/presentation/map_screen.dart';
import 'package:chargego/src/features/qr_scan/presentation/qr_scanner_screen.dart';
import 'package:chargego/src/features/rental/presentation/active_rental_screen.dart';
import 'package:chargego/src/features/payment/presentation/saved_cards_screen.dart';
import 'package:chargego/src/features/payment/presentation/add_card_screen.dart';
import 'package:chargego/src/features/history/presentation/rental_history_screen.dart';
import 'package:chargego/src/features/profile/presentation/profile_screen.dart';
import 'package:chargego/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:chargego/src/features/settings/presentation/settings_screen.dart';
import 'package:chargego/src/features/support/presentation/support_chat_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:chargego/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:chargego/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:chargego/src/features/auth/presentation/login_screen.dart';
import 'package:chargego/src/features/auth/presentation/register_screen.dart';
import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Manual provider for now as build_runner is having issues
final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/qr-scan',
        builder: (context, state) {
          final mode = state.extra is QrScanMode
              ? state.extra! as QrScanMode
              : QrScanMode.startRental;
          return QRScannerScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/active-rental',
        builder: (context, state) {
          final powerBankId = state.extra as String?;
          return ActiveRentalScreen(powerBankId: powerBankId);
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const SavedCardsScreen(),
      ),
      GoRoute(
        path: '/add-card',
        builder: (context, state) => const AddCardScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const RentalHistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportChatScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn) {
        if (!isLoggingIn && !isOnboarding) {
          return '/onboarding';
        }
      } else {
        if (isLoggingIn || isOnboarding) {
          return '/home';
        }
      }
      return null;
    },
  );
});
