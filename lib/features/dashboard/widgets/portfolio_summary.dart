import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';

class PortfolioSummary extends ConsumerStatefulWidget {
  final List<InvestorRequest> requests;

  const PortfolioSummary({super.key, required this.requests});

  @override
  ConsumerState<PortfolioSummary> createState() => _PortfolioSummaryState();
}

class _PortfolioSummaryState extends ConsumerState<PortfolioSummary> {
  double _totalPayouts = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTotalPayouts();
  }

  Future<void> _fetchTotalPayouts() async {
    if (widget.requests.isEmpty) return;
    final userId = widget.requests.first.userId;
    if (userId.isEmpty) return;
    
    final total = await ref.read(investorRepositoryProvider).getTotalPayouts(userId);
    if (mounted) {
      setState(() {
        _totalPayouts = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate metrics
    final confirmedRequests = widget.requests.where((r) => r.status.toLowerCase() == 'investment confirmed').toList();
    final totalInvested = confirmedRequests.fold(0.0, (sum, r) => sum + r.parsedAmount);
    final activeCount = confirmedRequests.length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withBlue(100), 
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Invested',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(totalInvested),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Active Plans',
                  activeCount.toString(),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Payouts',
                  NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN').format(_totalPayouts), 
                  Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
