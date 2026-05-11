import 'dart:convert';

import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
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

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              await context.push('/edit-profile');
            },
          ),
        ],
      ),
      body: authUser == null
          ? const EmptyState(
              icon: Icons.person_off_rounded,
              title: 'No user connected',
              subtitle: 'Sign in again to view your profile.',
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(authUser.id)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = (data?['nombre'] as String?)?.trim();
                final email =
                    (data?['email'] as String?)?.trim() ?? authUser.email;
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  children: [
                    BrandHeader(
                      title: name != null && name.isNotEmpty
                          ? name
                          : 'Sin nombre',
                      subtitle: email,
                      trailing: CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 34,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PremiumCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _ProfileTile(
                            icon: Icons.history_rounded,
                            title: 'Rental History',
                            onTap: () => context.push('/history'),
                          ),
                          _ProfileTile(
                            icon: Icons.payment_rounded,
                            title: 'Payment Methods',
                            onTap: () => context.push('/payment'),
                          ),
                          _ProfileTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Support',
                            onTap: () => context.push('/support'),
                          ),
                          _ProfileTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: ChargeGoColors.danger,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: ChargeGoColors.danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
