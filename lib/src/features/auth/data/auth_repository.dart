import 'package:chargego/src/features/auth/domain/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}

class MockAuthRepository implements AuthRepository {
  User? _currentUser;
  
  @override
  Stream<User?> authStateChanges() => Stream.value(_currentUser);

  @override
  User? get currentUser => _currentUser;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password == 'password') {
      _currentUser = User(id: '1', email: email, name: 'Test User');
      return _currentUser!;
    }
    throw Exception('Invalid password');
  }

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(id: '1', email: email, name: 'New User');
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}

// Manual provider for now
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
