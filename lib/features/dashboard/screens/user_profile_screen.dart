import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('User not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                 const SizedBox(height: 20),
                 CircleAvatar(
                   radius: 50,
                   backgroundColor: theme.primaryColor.withOpacity(0.1),
                   child: Text(
                     (profile['full_name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                     style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: theme.primaryColor),
                   ),
                 ),
                 const SizedBox(height: 16),
                 Text(
                   profile['full_name'] ?? 'User',
                   style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                 ),
                 Text(
                   profile['email'] ?? '',
                   style: const TextStyle(color: Colors.grey),
                 ),
                 const SizedBox(height: 32),
                 _buildInfoTile(context, Icons.phone, 'Phone', profile['phone'] ?? 'Not set'),
                 _buildInfoTile(context, Icons.calendar_today, 'Joined', 
                    profile['created_at'] != null 
                    ? DateFormat.yMMMd().format(DateTime.parse(profile['created_at'])) 
                    : '-'
                 ),
                 _buildInfoTile(context, Icons.badge, 'Role', (profile['role'] as String? ?? 'User').toUpperCase()),
                 
                 // Add Bank Details if present (assuming stored in user profile or separately, likely metadata)
                 // For now just basic info
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
