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

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  
  Future<void> _deleteAgent(String agentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Agent?'),
        content: const Text('This action cannot be undone. Referrals may lose their agent link.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('users').delete().eq('id', agentId);
        ref.refresh(agentsProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: Text('No agents found. Add one to get started.'));
          }

          // Build Dashboard-like stats at top? Or just list. 
          // Let's stick to a clean list with actions for now as per requirements.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.push('/agent-detail/${agent['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          child: Text(
                            (agent['full_name'] as String? ?? 'A')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(agent['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(agent['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Commission: ${agent['commission_percentage']}%', style: TextStyle(color: Colors.blue[800], fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('View Details')),
                            // Edit functionality could be added here (open create screen with data)
                            // const PopupMenuItem(value: 'edit', child: Text('Edit')), 
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (val) {
                             if (val == 'view') context.push('/agent-detail/${agent['id']}');
                             if (val == 'delete') _deleteAgent(agent['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading agents: $err')),
      ),
    );
  }
}
