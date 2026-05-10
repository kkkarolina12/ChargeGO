import 'package:chargego/src/app.dart';
import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/auth/domain/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App starts and shows onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const ChargeGoApp(),
      ),
    );

    expect(find.text('Welcome to ChargeGO'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String phoneNumber,
  }) async {}
}
