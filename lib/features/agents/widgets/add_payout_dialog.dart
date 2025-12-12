import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddPayoutDialog extends StatefulWidget {
  final String agentId;
  final List<dynamic> investments; // enriched with 'user_name'
  final double commissionPercentage;

  const AddPayoutDialog({super.key, required this.agentId, required this.investments, required this.commissionPercentage});

  @override
  State<AddPayoutDialog> createState() => _AddPayoutDialogState();
}

class _AddPayoutDialogState extends State<AddPayoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String? _selectedRequestId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  void _onInvestmentChanged(String? val) {
    debugPrint('Selected Investment ID: $val');
    setState(() {
      _selectedRequestId = val;
    });

    if (val != null) {
      // FIX: orElse must return a Map matching the list element type, not null.
      final inv = widget.investments.firstWhere(
        (i) => i['id'] == val, 
        orElse: () => <String, dynamic>{}
      );
      
      debugPrint('Found Investment Object: $inv');
      
      if (inv.isNotEmpty) {
         // Parse amount string (It should be clean number now, but keep some cleanup just in case)
         final rawAmount = inv['investment_amount'].toString();
         debugPrint('Raw Amount from object: $rawAmount');
         
         // Robust cleaning: remove everything except digits and dots
         final clean = rawAmount.replaceAll(RegExp(r'[^\d.]'), '');
         debugPrint('Cleaned Amount (Regex): $clean');

         final invested = double.tryParse(clean) ?? 0.0;
         debugPrint('Parsed Amount: $invested');
         
         debugPrint('Commission Percentage: ${widget.commissionPercentage}');

         if (invested > 0) {
            final comm = invested * (widget.commissionPercentage / 100);
            debugPrint('Calculated Commission: $comm');
            _amountCtrl.text = comm.toStringAsFixed(0); // Round for readability
         } else {
            debugPrint('Invested amount is 0 or failed to parse');
         }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRequestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an investment')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('payouts').insert({
        'request_id': _selectedRequestId,
        // user_id is NOT added as per constraint. Relation is via request_id.
        'amount': double.parse(_amountCtrl.text),
        'transaction_utr': _utrCtrl.text.isEmpty ? null : _utrCtrl.text,
        'payment_date': _selectedDate.toIso8601String(),
        'type': 'Commission',
        'status': 'Paid',
        'notes': _notesCtrl.text,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout recorded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _utrCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Commission Payout'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Select Investment
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Link to Investment', border: OutlineInputBorder()),
                  value: _selectedRequestId,
                  hint: const Text('Select Investment'),
                  isExpanded: true,
                  items: widget.investments.map<DropdownMenuItem<String>>((inv) {
                    final amt = inv['investment_amount'];
                    final plan = inv['plan_name'] ?? 'Plan';
                    final userName = inv['user_name'] ?? 'User';
                    return DropdownMenuItem(
                      value: inv['id'],
                      child: Text(
                        '$userName - $plan ($amt)',
                        maxLines: null, // Allow wrapping
                        softWrap: true,
                      ),
                    );
                  }).toList(),
                  onChanged: _onInvestmentChanged,
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                // 2. Amount
                TextFormField(
                  controller: _amountCtrl,
                  decoration: InputDecoration(
                    labelText: 'Commission Amount (₹)', 
                    border: const OutlineInputBorder(),
                    helperText: 'Auto-calculated @ ${widget.commissionPercentage}%',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // 3. UTR
                TextFormField(
                  controller: _utrCtrl,
                  decoration: const InputDecoration(labelText: 'Transaction UTR (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                // 4. Date Picker
                ListTile(
                  title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context, 
                      initialDate: _selectedDate, 
                      firstDate: DateTime(2020), 
                      lastDate: DateTime.now()
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
                const SizedBox(height: 16),

                // 5. Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Payout'),
        ),
      ],
    );
  }
}
