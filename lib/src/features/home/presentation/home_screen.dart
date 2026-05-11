import 'package:chargego/src/core/theme/app_theme.dart';
import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/rental/presentation/rental_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final rentalState = ref.watch(rentalControllerProvider);

    return PremiumScaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 34, showShadow: false),
            const SizedBox(width: 10),
            Text(
              'ChargeGO',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
          ),
        ],
      ),
      floatingActionButton: rentalState.activeRental == null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/qr-scan'),
              label: const Text(
                'Alquilar PowerBank',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandHeader(
              title: 'Hola, ${user?.name ?? 'Usuario'}',
              subtitle:
                  'Encuentra una estacion, escanea el codigo QR y mantente con bateria todo el dia.',
              trailing: const BrandLogo(size: 72, showShadow: false),
            ),
            const SizedBox(height: 18),
            if (rentalState.activeRental != null) ...[
              PremiumCard(
                onTap: () => context.push('/active-rental'),
                gradient: LinearGradient(
                  colors: [
                    ChargeGoColors.electric.withValues(alpha: 0.95),
                    ChargeGoColors.royal,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.battery_charging_full_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alquiler activo',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Tienes un powerbank en uso',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            PremiumCard(
              onTap: () => context.push('/map'),
              padding: const EdgeInsets.all(0),
              child: Container(
                height: 156,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ChargeGoColors.navy, ChargeGoColors.royal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Encuentra una estacion',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explora puntos ChargeGO cercanos y disponibilidad real.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Acciones rapidas'),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.06,
              children: [
                PremiumIconTile(
                  icon: Icons.person_rounded,
                  label: 'Mi perfil',
                  onTap: () => context.push('/profile'),
                ),
                PremiumIconTile(
                  icon: Icons.history_rounded,
                  label: 'Historial',
                  onTap: () => context.push('/history'),
                ),
                PremiumIconTile(
                  icon: Icons.payment_rounded,
                  label: 'Metodos de pago',
                  onTap: () => context.push('/payment'),
                ),
                PremiumIconTile(
                  icon: Icons.share_rounded,
                  label: 'Invitar amigos',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La funcion de compartir llegara pronto.',
                        ),
                      ),
                    );
                  },
                ),
                PremiumIconTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Ayuda/soporte',
                  onTap: () => context.push('/support'),
                ),
                PremiumIconTile(
                  icon: Icons.settings_outlined,
                  label: 'Ajustes',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
