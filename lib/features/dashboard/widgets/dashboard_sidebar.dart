import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/core/providers/theme_provider.dart';
import 'package:investorapp_eminates/features/dashboard/widgets/support_dialog.dart';
import 'package:intl/intl.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Determines provider (e.g. 'google', 'email')
    final provider = currentUser?.appMetadata['provider'] ?? 'email';
    final createdAt = currentUser?.createdAt;
    
    // Determine if system is dark if mode is system
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            //dark bg for light mode
            color: isDark ? Colors.blue : Theme.of(context).primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  userProfileAsync.valueOrNull?['full_name'] ?? 'User',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                Text(
                  userProfileAsync.valueOrNull?['email'] ?? '',
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (createdAt != null)
                   Text(
                     'Member since: ${DateFormat.yMMMd().format(DateTime.parse(createdAt))}',
                     style: GoogleFonts.outfit(fontSize: 12, color: Colors.white),
                   ),
                 Text(
                   'Login: ${provider.toUpperCase()}',
                   style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
                 ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              context.pop(); 
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Plans'),
            onTap: () {
              context.pop();
              context.push('/plans');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Support'),
            onTap: () {
              context.pop();
              showDialog(context: context, builder: (_) => const SupportDialog());
            },
          ),
          Builder(
            builder: (context) {
              final profile = userProfileAsync.valueOrNull;
              final bool hasReferred = profile != null && profile['referred_by'] != null;
              
              return ListTile(
                leading: Icon(
                  Icons.confirmation_number_outlined, 
                  color: hasReferred ? Colors.grey : null
                ),
                title: Text(
                  hasReferred ? 'Referral Code (Used)' : 'Referral Code',
                  style: TextStyle(color: hasReferred ? Colors.grey : null),
                ),
                trailing: hasReferred 
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20) 
                    : null,
                onTap: hasReferred ? null : () {
                  context.pop();
                  context.push('/enter-referral');
                },
              );
            }
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings (Dark Mode)'),
             trailing: Switch(
               value: isDark,
               onChanged: (val) {
                 ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
               },
             ),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authRepositoryProvider).signOut();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
