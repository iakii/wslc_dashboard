import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wsl_container.dart';
import '../providers/container_providers.dart';
import 'container_detail_page.dart';

/// Container management page — list, create, start, stop
class ContainersPage extends ConsumerStatefulWidget {
  const ContainersPage({super.key});

  @override
  ConsumerState<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends ConsumerState<ContainersPage> {
  // Create dialog controllers
  final _imageCtrl = TextEditingController(text: 'library/alpine:latest');
  final _nameCtrl = TextEditingController(text: 'Test Container');
  final _cmdCtrl = TextEditingController(text: '/bin/sh');

  @override
  void dispose() {
    _imageCtrl.dispose();
    _nameCtrl.dispose();
    _cmdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containersAsync = ref.watch(containerListProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Containers')),
      content: containersAsync.when(
        loading: () => const Center(child: ProgressRing()),
        error: (err, _) => _buildError(context, err.toString()),
        data: (list) =>
            list.isEmpty ? _buildEmpty(context) : _buildList(context, list),
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.status_error_full, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load containers'),
          const SizedBox(height: 4),
          Text(msg, style: FluentTheme.of(context).typography.caption),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(containerListProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const Icon(FluentIcons.cube_shape, size: 48),
          Text('No containers', style: theme.typography.title),
          const Text('Create your first container to get started.'),
          FilledButton(
            onPressed: () => _showCreateDialog(context),
            child: const Text('Create Container'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<WslContainer> containers) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              FilledButton(
                onPressed: () => _showCreateDialog(context),
                child: const Text('Create'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () =>
                    ref.read(containerListProvider.notifier).refresh(),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: containers.length,
            itemBuilder: (ctx, i) => _buildCard(context, containers[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, WslContainer c) {
    final theme = FluentTheme.of(context);
    final isRunning = c.status == ContainerStatus.running;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            FluentPageRoute<Widget>(
              builder: (_) => ContainerDetailPage(containerId: c.id),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isRunning ? Colors.green : Colors.grey[60]).withAlpha(
                    26,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRunning ? FluentIcons.cube_shape : FluentIcons.cube_shape,
                  size: 20,
                  color: isRunning ? Colors.green : Colors.grey[60],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: theme.typography.bodyStrong),
                    const SizedBox(height: 2),
                    Text(c.imageName, style: theme.typography.caption),
                  ],
                ),
              ),
              _buildStatusBadge(context, c.status),
              const SizedBox(width: 8),
              if (c.status == ContainerStatus.created ||
                  c.status == ContainerStatus.stopped)
                IconButton(
                  icon: const Icon(FluentIcons.play_solid, size: 18),
                  onPressed: () {
                    ref.read(containerListProvider.notifier).start(c.id);
                  },
                ),
              if (isRunning)
                IconButton(
                  icon: const Icon(FluentIcons.stop_solid, size: 18),
                  onPressed: () {
                    ref.read(containerListProvider.notifier).stop(c.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, ContainerStatus s) {
    Color color;
    String text;
    switch (s) {
      case ContainerStatus.running:
        color = Colors.green;
        text = 'Running';
        break;
      case ContainerStatus.stopped:
        color = Colors.grey;
        text = 'Stopped';
        break;
      case ContainerStatus.created:
        color = Colors.orange;
        text = 'Created';
        break;
      default:
        color = Colors.grey;
        text = s.name;
    }
    return Container(
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
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Create Container'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              InfoLabel(
                label: 'Image',
                child: TextBox(
                  placeholder: 'library/alpine:latest',
                  controller: _imageCtrl,
                ),
              ),
              InfoLabel(
                label: 'Name (optional)',
                child: TextBox(
                  placeholder: 'my-container',
                  controller: _nameCtrl,
                ),
              ),
              InfoLabel(
                label: 'Command',
                child: TextBox(placeholder: '/bin/sh', controller: _cmdCtrl),
              ),
            ],
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'image': _imageCtrl.text.trim(),
                'name': _nameCtrl.text.trim(),
                'cmd': _cmdCtrl.text.trim(),
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await ref
          .read(containerListProvider.notifier)
          .create(
            image: result['image']!,
            name: result['name']!,
            cmd: result['cmd']!.split(' '),
          );
    }
  }
}
