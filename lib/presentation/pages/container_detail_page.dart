import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wsl_container.dart';
import '../../domain/entities/wsl_process_output.dart';
import '../providers/container_providers.dart';

/// Container detail page — info header + action bar + live log terminal
class ContainerDetailPage extends ConsumerStatefulWidget {
  const ContainerDetailPage({super.key, required this.containerId});

  final String containerId;

  @override
  ConsumerState<ContainerDetailPage> createState() =>
      _ContainerDetailPageState();
}

class _ContainerDetailPageState extends ConsumerState<ContainerDetailPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final List<WslProcessOutput> _logs = [];

  void _onLog(WslProcessOutput output) {
    setState(() => _logs.add(output));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to log stream
    ref.listen(containerLogsProvider(widget.containerId), (_, next) {
      next.whenData(_onLog);
    });

    final containersAsync = ref.watch(containerListProvider);
    final container = containersAsync.whenOrNull(
      data: (list) {
        try {
          return list.firstWhere((c) => c.id == widget.containerId);
        } catch (_) {
          return null;
        }
      },
    );

    final isRunning = container?.status == ContainerStatus.running;

    return ScaffoldPage(
      header: PageHeader(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 12),
          child: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(container?.name ?? widget.containerId),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRunning)
              FilledButton(
                child: const Text('Start'),
                onPressed: () => ref
                    .read(containerListProvider.notifier)
                    .start(widget.containerId),
              ),
            if (isRunning) ...[
              FilledButton(
                child: const Text('Stop'),
                onPressed: () => ref
                    .read(containerListProvider.notifier)
                    .stop(widget.containerId),
              ),
              const SizedBox(width: 8),
            ],
            Button(onPressed: _confirmDelete, child: const Text('Delete')),
          ],
        ),
      ),
      content: Column(
        children: [
          // Info bar
          if (container != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Card(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      'Image: ${container.imageName}',
                      style: FluentTheme.of(context).typography.caption,
                    ),
                    const SizedBox(width: 16),
                    _statusBadge(context, container.status),
                    const Spacer(),
                    Text(
                      '${_logs.length} lines',
                      style: FluentTheme.of(context).typography.caption,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Log terminal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                padding: const EdgeInsets.all(8),
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Waiting for logs...',
                            style: TextStyle(color: Color(0xFF808080)),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(8),
                          itemCount: _logs.length,
                          itemBuilder: (_, i) => _logLine(context, _logs[i]),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logLine(BuildContext context, WslProcessOutput output) {
    final color = switch (output.stream) {
      'stderr' => material.Colors.redAccent,
      'exit' => material.Colors.yellowAccent,
      _ => const Color(0xFFD4D4D4),
    };
    final text = output.text.endsWith('\n') ? output.text : '${output.text}\n';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Consolas, monospace',
          fontSize: 13,
        ).copyWith(color: color),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, ContainerStatus s) {
    final (color, text) = switch (s) {
      ContainerStatus.running => (Colors.green, 'Running'),
      ContainerStatus.stopped => (Colors.grey, 'Stopped'),
      ContainerStatus.created => (Colors.orange, 'Created'),
      _ => (Colors.grey, s.name),
    };
    return SelectionArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: FluentTheme.of(
            context,
          ).typography.caption?.copyWith(color: color),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Delete Container'),
        content: const Text(
          'This will permanently delete the container. Continue?',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          Button(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await ref.read(containerListProvider.notifier).delete(widget.containerId);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
