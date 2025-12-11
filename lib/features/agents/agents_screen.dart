import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

final agentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('users')
      .select('id, full_name, email, role, commission_percentage, created_at')
      .eq('role', 'agent')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

class AgentsScreen extends ConsumerWidget {
  const AgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Agents'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-agent').then((_) => ref.refresh(agentsProvider)),
        label: const Text('Add Agent'),
        icon: const Icon(Icons.person_add),
      ),
      body: agentsAsync.when(
        data: (agents) {
          if (agents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No agents found'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (agent['full_name'] as String? ?? 'A')[0].toUpperCase(),
                    ),
                  ),
                  title: Text(agent['full_name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agent['email'] ?? ''),
                      const SizedBox(height: 4),
                      Text('Commission: ${agent['commission_percentage']}%'),
                    ],
                  ),
                  trailing: Text(
                    timeago.format(DateTime.parse(agent['created_at'])),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
