import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/core/providers/theme_provider.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Determine if system is dark if mode is system
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            accountName: Text(
              userProfileAsync.valueOrNull?['full_name'] ?? 'User',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              userProfileAsync.valueOrNull?['email'] ?? '',
              style: GoogleFonts.outfit(),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
               context.pop(); 
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
            },
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
