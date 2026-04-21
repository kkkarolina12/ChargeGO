import 'package:chargego/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Si usaste 'flutterfire configure'

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 IMPORTANTE: Inicializar Firebase ANTES de correr la app
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // Descomenta si tienes firebase_options.dart
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
  }

  runApp(
    const ProviderScope(
      child: ChargeGoApp(),
    ),
  );
}