import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:chargego/src/features/history/data/history_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RentalHistoryScreen extends ConsumerWidget {
  const RentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final historyAsync = ref.watch(rentalHistoryProvider(user?.id ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental History'),
      ),
      body: historyAsync.when(
        data: (rentals) => rentals.isEmpty
            ? const Center(child: Text('No history found'))
            : ListView.builder(
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  final rental = rentals[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Rental #${rental.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(rental.startTime)}'),
                          Text('Duration: ${rental.endTime?.difference(rental.startTime).inMinutes ?? 0} mins'),
                        ],
                      ),
                      trailing: Text(
                        '\$${rental.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () {
                        // Navigate to rental details if needed
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
