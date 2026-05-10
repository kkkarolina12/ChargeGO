import 'dart:convert';

import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/edit-profile');
            },
          ),
        ],
      ),
      body: authUser == null
          ? const Center(child: Text('No hay usuario conectado'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(authUser.id)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();

                final name = (data?['nombre'] as String?)?.trim();
                final email = (data?['email'] as String?)?.trim() ?? authUser.email;
                final avatarBase64 =
                    (data?['avatar_base64'] as String?)?.trim() ?? '';

                ImageProvider? avatarImage;

                if (avatarBase64.isNotEmpty) {
                  try {
                    avatarImage = MemoryImage(base64Decode(avatarBase64));
                  } catch (_) {
                    avatarImage = null;
                  }
                }

                return ListView(
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        name != null && name.isNotEmpty ? name : 'Sin nombre',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Center(
                      child: Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Rental History'),
                      onTap: () => context.push('/history'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.payment),
                      title: const Text('Payment Methods'),
                      onTap: () => context.push('/payment'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Support'),
                      onTap: () => context.push('/support'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
