import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminBankSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (settingsList) {
          if (settingsList.isEmpty) {
            return const Center(child: Text('No bank details added yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: settingsList.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = settingsList[index];
              final details = item['value'] as Map<String, dynamic>;
              final isActive = item['is_active'] as bool? ?? true;
              print('DEBUG: Item keys: ${item.keys.toList()}'); // Check what we actually have
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    child: Icon(Icons.account_balance, color: isActive ? Colors.green : Colors.grey),
                  ),
                  title: Text(item['description'] ?? details['bank_name'] ?? 'Bank Account'),
                  subtitle: Text('${details['bank_name']} - ${details['account_no']}\nIFSC: ${details['ifsc']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (val) => _toggleActive(item['id'], !isActive, item, details),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(existingItem: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteSetting(item['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Bank Account'),
      ),
    );
  }

  Future<void> _toggleActive(String id, bool newState, Map<String, dynamic> item, Map<String, dynamic> value) async {
     try {
       await ref.read(investorRepositoryProvider).saveAppSetting(
         id: id,
         key: 'bank_details',
         value: value,
         description: item['description'],
         isActive: newState,
       );
       ref.refresh(adminBankSettingsProvider);
     } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
     }
  }
  
  Future<void> _deleteSetting(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('Are you sure you want to delete this bank account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(investorRepositoryProvider).deleteAppSetting(id);
        ref.refresh(adminBankSettingsProvider);
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? existingItem}) {
    final isEdit = existingItem != null;
    final details = isEdit ? existingItem!['value'] as Map<String, dynamic> : {};
    
    final descCtrl = TextEditingController(text: isEdit ? existingItem!['description'] : '');
    final bankNameCtrl = TextEditingController(text: details['bank_name']);
    final accNameCtrl = TextEditingController(text: details['account_name']);
    final accNoCtrl = TextEditingController(text: details['account_no']);
    final ifscCtrl = TextEditingController(text: details['ifsc']);
    final branchCtrl = TextEditingController(text: details['branch']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Bank Account' : 'Add Bank Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (e.g. Primary)')),
              const SizedBox(height: 12),
              TextFormField(controller: bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank Name')),
              const SizedBox(height: 12),
              TextFormField(controller: accNameCtrl, decoration: const InputDecoration(labelText: 'Account Holder Name')),
              const SizedBox(height: 12),
              TextFormField(controller: accNoCtrl, decoration: const InputDecoration(labelText: 'Account Number')),
              const SizedBox(height: 12),
              TextFormField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC Code')),
              const SizedBox(height: 12),
              TextFormField(controller: branchCtrl, decoration: const InputDecoration(labelText: 'Branch')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (bankNameCtrl.text.isEmpty || accNoCtrl.text.isEmpty) return;
              
              Navigator.pop(ctx);
              try {
                final value = {
                  'bank_name': bankNameCtrl.text,
                  'account_name': accNameCtrl.text,
                  'account_no': accNoCtrl.text,
                  'ifsc': ifscCtrl.text,
                  'branch': branchCtrl.text,
                };
                
                final String? editId = isEdit ? existingItem!['id'] : null;
                print('DEBUG: Saving App Setting. isEdit: $isEdit, ID: $editId');
                
                await ref.read(investorRepositoryProvider).saveAppSetting(
                  id: editId,
                  key: 'bank_details',
                  value: value,
                  description: descCtrl.text,
                  isActive: isEdit ? (existingItem!['is_active'] ?? true) : true,
                );
                ref.refresh(adminBankSettingsProvider);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved successfully.')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Provider for Admin Settings List
final adminBankSettingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(investorRepositoryProvider).getAllAppSettings('bank_details');
});
