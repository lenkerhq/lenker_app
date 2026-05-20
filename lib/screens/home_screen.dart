import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedEntryIndex = 0;

  @override
  void initState() {
    super.initState();
    final sub = context.read<SubscriptionService>();
    if (sub.access == null && !sub.loading) {
      sub.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lenker'),
        actions: [
          IconButton(icon: const Icon(Icons.bug_report), onPressed: () => Navigator.of(context).pushNamed('/diagnostics')),
        ],
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, sub, _) {
          if (sub.loading && sub.access == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sub.error != null && sub.access == null) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(sub.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: sub.refresh, child: const Text('Retry')),
            ]));
          }
          final access = sub.access;
          if (access == null) return const SizedBox.shrink();
          return _buildContent(context, access, sub);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SubscriptionAccess access, SubscriptionService sub) {
    final entries = access.entries;
    final selectedEntry = entries.isNotEmpty && _selectedEntryIndex < entries.length ? entries[_selectedEntryIndex] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard(context, access),
          const SizedBox(height: 24),
          if (entries.isNotEmpty) ...[
            Text('Region', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedEntryIndex,
              items: entries.asMap().entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text('${e.value.node.name} (${e.value.node.region})'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedEntryIndex = v ?? 0),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            if (selectedEntry != null)
              Text('${selectedEntry.address}:${selectedEntry.port} • ${selectedEntry.protocol}',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: null,
              child: const Text('Connect (VPN engine coming soon)'),
            ),
          ),
          const SizedBox(height: 16),
          if (sub.error != null)
            Text(sub.error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          TextButton(onPressed: sub.refresh, child: const Text('Refresh subscription')),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context, SubscriptionAccess access) {
    final traffic = access.trafficLimitBytes != null
        ? '${_formatBytes(access.trafficUsedBytes)} / ${_formatBytes(access.trafficLimitBytes!)}'
        : '${_formatBytes(access.trafficUsedBytes)} / unlimited';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(access.planName, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Chip(label: Text(access.status)),
          ]),
          const SizedBox(height: 8),
          Text('Expires: ${access.expiresAt.split("T").first}'),
          Text('Traffic: $traffic'),
          Text('Devices: ${access.deviceLimit}'),
        ]),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
