import 'package:chargego/src/core/firebase/firestore_collections.dart';
import 'package:chargego/src/features/auth/domain/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
  Future<void> resetPasswordWithRecoveryCode({
    required String email,
    required String code,
    required String newPassword,
  });
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String phoneNumber,
  });
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  User? _currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  @override
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges().asyncMap(_mapFirebaseUser);
  }

  @override
  User? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return _currentUser;
    }

    if (_currentUser?.id == firebaseUser.uid) {
      return _currentUser;
    }

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('No se pudo iniciar sesion.');
      }
      final user = await _loadOrCreateUser(firebaseUser);
      if (user.status.toLowerCase() == 'bloqueado') {
        await signOut();
        throw Exception('Este usuario esta bloqueado.');
      }
      return user;
    } on firebase_auth.FirebaseAuthException catch (error) {
      final localUser = await _signInWithRecoveredPassword(email, password);
      if (localUser != null) return localUser;
      throw Exception(_authMessage(error));
    }
  }

  @override
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email.trim(),
        name: _defaultNameFromEmail(email),
      );
      await _users.doc(user.id).set({
        ...user.toFirestoreSchema(),
        'fecha_registro': FieldValue.serverTimestamp(),
      });
      _currentUser = user;
      return user;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String phoneNumber,
  }) async {
    await _users.doc(userId).set({
      'id_usuario': userId,
      'nombre': name.trim(),
      'telefono': phoneNumber.trim(),
    }, SetOptions(merge: true));

    if (_auth.currentUser?.uid == userId) {
      await _auth.currentUser?.updateDisplayName(name.trim());
    }

    _currentUser = _currentUser?.copyWith(
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
    );
  }

  @override
  Future<void> resetPasswordWithRecoveryCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedCode = code.trim();

    if (!normalizedEmail.contains('@')) {
      throw Exception('Introduce un correo valido.');
    }
    if (normalizedCode != _demoRecoveryCode) {
      throw Exception('El codigo de recuperacion no es valido.');
    }
    if (newPassword.length < 6) {
      throw Exception('La contrasena debe tener al menos 6 caracteres.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recoveredPasswordKey(normalizedEmail), newPassword);
    await prefs.setString(_lastRecoveredEmailKey, normalizedEmail);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _auth.signOut();
  }

  Future<User?> _mapFirebaseUser(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      return _currentUser;
    }

    return _loadOrCreateUser(firebaseUser);
  }

  Future<User> _loadOrCreateUser(firebase_auth.User firebaseUser) async {
    final userDoc = _users.doc(firebaseUser.uid);
    final snapshot = await userDoc.get();

    if (snapshot.exists && snapshot.data() != null) {
      final user = User.fromJson({
        ...snapshot.data()!,
        'id_usuario': firebaseUser.uid,
        'email': snapshot.data()!['email'] ?? firebaseUser.email ?? '',
      });
      _currentUser = user;
      return user;
    }

    final user = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name:
          firebaseUser.displayName ??
          _defaultNameFromEmail(firebaseUser.email ?? ''),
      phoneNumber: firebaseUser.phoneNumber,
    );
    await userDoc.set({
      ...user.toFirestoreSchema(),
      'fecha_registro': FieldValue.serverTimestamp(),
    });
    _currentUser = user;
    return user;
  }

  Future<User?> _signInWithRecoveredPassword(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final recoveredPassword = prefs.getString(
      _recoveredPasswordKey(normalizedEmail),
    );
    if (recoveredPassword == null || recoveredPassword != password) {
      return null;
    }

    try {
      final snapshot = await _users
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final user = User.fromJson({
          ...doc.data(),
          'id_usuario': doc.id,
          'email': doc.data()['email'] ?? normalizedEmail,
        });
        _currentUser = user;
        return user;
      }
    } catch (_) {
      // Firestore may require Firebase Auth for user reads; keep local access
      // usable for the demo reset flow.
    }

    final user = User(
      id: _localUserId(normalizedEmail),
      email: normalizedEmail,
      name: _defaultNameFromEmail(normalizedEmail),
    );
    _currentUser = user;
    return user;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

String _defaultNameFromEmail(String email) {
  final value = email.trim();
  if (!value.contains('@')) return value;
  return value.split('@').first;
}

const _demoRecoveryCode = '123456';
const _lastRecoveredEmailKey = 'chargego_last_recovered_email';

String _recoveredPasswordKey(String email) {
  return 'chargego_recovered_password_${email.trim().toLowerCase()}';
}

String _localUserId(String email) {
  final normalized = email.trim().toLowerCase();
  return 'local_${normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
}

String _authMessage(firebase_auth.FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'El email no es valido.';
    case 'user-disabled':
      return 'Este usuario esta bloqueado.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email o contrasena incorrectos.';
    case 'email-already-in-use':
      return 'Ya existe una cuenta con este email.';
    case 'weak-password':
      return 'La contrasena es demasiado debil.';
    default:
      return error.message ?? 'Error de autenticacion.';
  }
}
