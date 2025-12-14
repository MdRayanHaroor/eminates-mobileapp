import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';

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
               style: GoogleFonts.outfit(
                 fontSize: 32,
                 fontWeight: FontWeight.bold,
                 color: Colors.black,
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
               )
             ]
          ],
        ),
      ),
    );
  }
}
