import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/dashboard/agent_dashboard_screen.dart';
import 'package:investorapp_eminates/features/dashboard/admin_dashboard_screen.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/dashboard/providers/notification_provider.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/core/services/update_service.dart';
import 'package:investorapp_eminates/core/widgets/update_dialog.dart';
import 'package:investorapp_eminates/core/providers/theme_provider.dart';

import 'widgets/dashboard_sidebar.dart';
import 'widgets/auto_sliding_plans.dart';
import 'widgets/request_card.dart';
import 'widgets/portfolio_summary.dart';
import 'package:investorapp_eminates/features/plans/plans_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _checkedWalkthrough = false;
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkForUpdates();
       // Initial check if data already available
       _initialWalkthroughCheck();
    });
  }

  void _initialWalkthroughCheck() {
    final roleAsync = ref.read(userRoleProvider);
    // Explicitly check for 'user'. If null (loading/unknown), wait. 
    // If 'agent' or 'admin', do NOT show.
    if (roleAsync.hasValue && roleAsync.value == 'user') {
      _triggerWalkthrough();
    }
  }

  void _triggerWalkthrough() {
    if (_checkedWalkthrough) return;
    _checkedWalkthrough = true;
    if (mounted) context.push('/walkthrough');
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await ref.read(updateServiceProvider).checkForUpdate();
    if (updateInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !updateInfo.forceUpdate,
        builder: (context) => UpdateDialog(updateInfo: updateInfo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    final user = ref.watch(currentUserProvider);
    final requestsAsync = ref.watch(userRequestsProvider);
    final theme = Theme.of(context);

    // Listen for role changes to trigger walkthrough if not yet done
    ref.listen(userRoleProvider, (prev, next) {
      if (next.value == 'user') {
         _triggerWalkthrough();
      }
    });

    return roleAsync.when(
      data: (role) {
        final actualRole = role ?? 'user';

        if (actualRole == 'agent') {
          return const AgentDashboardScreen();
        }

        if (actualRole == 'admin') {
           return const AdminDashboardScreen();
        }

        // User Dashboard with Vibrant Theme
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: theme.scaffoldBackgroundColor,
          drawer: const DashboardSidebar(),
          appBar: AppBar(
            backgroundColor: theme.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Text('Dashboard', 
                style: GoogleFonts.outfit(
                   fontWeight: FontWeight.bold, 
                   color: Colors.white
                )
            ),
            actions: [
                 IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => context.push('/notifications'),
                ),
            ],
          ),
          body: _buildBody(actualRole, requestsAsync),
          floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 2) 
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/onboarding'),
                label: const Text('Add Investment'),
                icon: const Icon(Icons.add),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              )
            : null,
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
               labelTextStyle: MaterialStateProperty.all(
                  GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500)
               ),
               indicatorColor: theme.primaryColor.withOpacity(0.2),
               iconTheme: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                     return IconThemeData(color: theme.primaryColor);
                  }
                  return IconThemeData(color: Colors.grey.shade600);
               }),
            ),
            child: NavigationBar(
              backgroundColor: theme.cardColor,
              elevation: 4,
              shadowColor: Colors.black12,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: 'Portfolio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.trending_up), 
                  selectedIcon: Icon(Icons.trending_up), 
                  label: 'My Investment',
                ),
                NavigationDestination(
                  icon: Icon(Icons.article_outlined),
                  selectedIcon: Icon(Icons.article),
                  label: 'Plans',
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildBody(String role, AsyncValue<List<InvestorRequest>> requestsAsync) {
    switch (_selectedIndex) {
      case 0: // Home
        return _buildHomeView(requestsAsync);
      case 1: // Portfolio (Confirmed) - Now includes Summary
        return _buildPortfolioView(requestsAsync);
      case 2: // My Investment (Others)
        return _buildFilteredList(requestsAsync, (r) => r.status.toLowerCase() != 'investment confirmed', 'No active requests.');
      case 3: // Plans (Replaces Settings)
        return const PlansScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeView(AsyncValue<List<InvestorRequest>> requestsAsync) {
     return RefreshIndicator(
       onRefresh: () async {
          ref.refresh(userRequestsProvider);
          ref.refresh(plansProvider);
       },
       child: SingleChildScrollView(
         physics: const AlwaysScrollableScrollPhysics(),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              const SizedBox(height: 16),
              const AutoSlidingPlans(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recent Requests',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              // List of all requests
              requestsAsync.when(
                data: (requests) {
                  if (requests.isEmpty) {
                     return const Padding(
                       padding: EdgeInsets.all(32.0),
                       child: Center(child: Text('No investment requests yet.')),
                     );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                       return RequestCard(request: requests[index]);
                    },
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 80),
           ],
         ),
       ),
     );
  }

  Widget _buildFilteredList(AsyncValue<List<InvestorRequest>> requestsAsync, bool Function(InvestorRequest) filter, String emptyMsg) {
    return requestsAsync.when(
      data: (requests) {
         final filtered = requests.where((r) => filter(r)).toList();
         if (filtered.isEmpty) {
            return RefreshIndicator(
               onRefresh: () async => ref.refresh(userRequestsProvider),
               child: Stack(
                 children: [
                   ListView(), // Empty list view for pull to refresh physics
                   Center(child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                       const SizedBox(height: 16),
                       Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
                     ],
                   )),
                 ],
               ),
            );
         }
         return RefreshIndicator(
           onRefresh: () async => ref.refresh(userRequestsProvider),
           child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) => RequestCard(request: filtered[index]),
           ),
         );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSettingsView() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
             leading: const Icon(Icons.dark_mode),
             title: const Text('Dark Mode'),
             trailing: Switch(
               value: isDark,
               onChanged: (val) {
                 ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
               },
             ),
          ),
        ),
        // Add more settings here if needed? User mainly asked for theme toggle.
      ],
    );
  }

  Widget _buildPortfolioView(AsyncValue<List<InvestorRequest>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
         final confirmed = requests.where((r) => r.status.toLowerCase() == 'investment confirmed').toList();
         
         return RefreshIndicator(
           onRefresh: () async => ref.refresh(userRequestsProvider),
           child: CustomScrollView(
             slivers: [
               SliverToBoxAdapter(
                 child: PortfolioSummary(requests: requests),
               ),
               if (confirmed.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No active investments yet.')),
                  )
               else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: RequestCard(request: confirmed[index]),
                      ),
                      childCount: confirmed.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
             ],
           ),
         );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
