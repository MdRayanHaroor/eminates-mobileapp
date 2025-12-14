import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/models/payout.dart';
import 'package:investorapp_eminates/repositories/investor_repository.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/core/utils/error_utils.dart';

final payoutsProvider = FutureProvider.autoDispose.family<List<Payout>, String>((ref, requestId) async {
  return ref.watch(investorRepositoryProvider).getPayouts(requestId);
});

class PayoutHistoryScreen extends ConsumerWidget {
  final String requestId;

  const PayoutHistoryScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(payoutsProvider(requestId));
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payout History')),
      body: payoutsAsync.when(
        data: (originalPayouts) {
          final payouts = isAdminAsync.value == true 
              ? originalPayouts 
              : originalPayouts.where((p) => p.type.toLowerCase() != 'commission').toList();

          if (payouts.isEmpty) {
            return const Center(child: Text('No payouts recorded yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payouts.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final payout = payouts[index];
              return _buildPayoutCard(context, payout);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: isAdminAsync.when(
        data: (isAdmin) => isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _showAddPayoutDialog(context, ref),
                label: const Text('Add Payout'),
                icon: const Icon(Icons.add),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildPayoutCard(BuildContext context, Payout payout) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isPaid = payout.status == 'Paid';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          child: Icon(
            isPaid ? Icons.check : Icons.schedule,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(payout.type, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.yMMMd().format(payout.paymentDate ?? DateTime.now())),
            if (payout.transactionUtr != null)
              Text('UTR: ${payout.transactionUtr}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currencyFormat.format(payout.amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid ? Colors.green : Colors.black87)),
            Text(payout.status, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _showAddPayoutDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final utrController = TextEditingController();
    String type = 'Profit';
    String status = 'Paid';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Payout Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Profit', 'Principal', 'Bonus']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Paid', 'Scheduled']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => status = v!),
                ),
                if (status == 'Paid') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: utrController,
                    decoration: const InputDecoration(labelText: 'Transaction UTR'),
                  ),
                ],
                const SizedBox(height: 16),
                InputDatePickerFormField(
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDate: selectedDate,
                  onDateSubmitted: (date) => selectedDate = date,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null) return;

                final payout = Payout(
                  requestId: requestId,
                  amount: amount,
                  type: type,
                  status: status,
                  transactionUtr: status == 'Paid' ? utrController.text : null,
                  paymentDate: selectedDate,
                );

                try {
                  await ref.read(investorRepositoryProvider).addPayout(payout);
                  ref.invalidate(payoutsProvider(requestId));
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  // Handle error
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
