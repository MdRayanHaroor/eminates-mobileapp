import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final String? message;
  const SplashScreen({super.key, this.message});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Temporary seed
    ref.read(investorRepositoryProvider).seedInvestmentPlans();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Image.asset(
               'assets/eminates_icon_png.png',
               width: 150,
               height: 150,
               errorBuilder: (c,o,s) => const Icon(Icons.flash_on, size: 80, color: Colors.amber),
             ),
             const SizedBox(height: 24),
             Text(
               'Eminates',
               style: const TextStyle(
                 fontSize: 32,
                 fontWeight: FontWeight.bold,
                 color: Colors.black,
                 fontFamily: 'Outfit', // If you have it locally, otherwise system font
               ),
             ),
             if (widget.message != null) ...[
               const SizedBox(height: 16),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 32),
                 child: Text(
                   widget.message!,
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.red),
                 ),
               ),
               const SizedBox(height: 24),
               ElevatedButton.icon(
                 onPressed: _checkConnectivity,
                 icon: const Icon(Icons.refresh),
                 label: const Text('Retry'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).primaryColor,
                   foregroundColor: Colors.white,
                 ),
               ),
             ]
          ],
        ),
      ),
    );
  }

  Future<void> _checkConnectivity() async {
    final bool hasConnection = await InternetConnectionChecker().hasConnection;
    if (hasConnection && mounted) {
      // Refresh router provided to re-evaluate redirect logic or just go home
      // Checking if user is logged in might be needed, but usually router redirect handles it.
      // For now, let's try to go to initial route or refresh.
      // Easiest is to go to '/' which is usually the entry point handled by redirect logic.
      context.go('/'); 
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Still no internet connection. Please check your settings.')),
         );
      }
    }
}
}
