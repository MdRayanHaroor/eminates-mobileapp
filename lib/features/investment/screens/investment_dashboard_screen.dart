import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class InvestmentDashboardScreen extends ConsumerWidget {
  final InvestorRequest request;

  const InvestmentDashboardScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    // Parse amount from string like "₹3,00,000 - Silver Plan"
    double amount = 0;
    String planName = 'Investment Plan';
    
    if (request.investmentAmount != null) {
      final parts = request.investmentAmount!.split('–');
      if (parts.isNotEmpty) {
        final amtStr = parts[0].replaceAll(RegExp(r'[^\d.]'), '');
        amount = double.tryParse(amtStr) ?? 0;
        if (parts.length > 1) planName = parts[1].trim();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Investment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Active Plan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(planName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Invested Amount', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(currencyFormat.format(amount), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Join Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(DateFormat.yMMMd().format(request.transactionDate ?? DateTime.now()), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Next Payout (Est)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          // Dummy calc: +3 months
                          Text(DateFormat.yMMMd().format(DateTime.now().add(const Duration(days: 90))), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Grid
            Row(
              children: [
                 Expanded(child: _buildStatCard(context, 'Total ROI', '₹0', Icons.trending_up, Colors.blue)),
                 const SizedBox(width: 16),
                 Expanded(child: _buildStatCard(context, 'Next Payout', 'Scheduled', Icons.schedule, Colors.orange)),
              ],
            ),
            const SizedBox(height: 24),

            // Actions
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payout History', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/payout-history/${request.id}');
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Investment Documents', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                 context.push('/investment-documents', extra: request);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
