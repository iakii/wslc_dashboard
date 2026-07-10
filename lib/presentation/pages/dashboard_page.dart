import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wsl_session.dart';
import '../providers/session_providers.dart';

/// WSL Session overview page — status card + statistics + actions
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // ======== Create Session Dialog Fields ========
  final _nameController = TextEditingController(text: 'wslc_dashboard');
  final _pathController = TextEditingController(text: r'D:\Kai\docker\wslc');
  int _cpuCount = 2;
  int _memoryMB = 2048;

  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  // ======== Build ========

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);
    final isSessionReady = ref.watch(isSessionReadyProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Overview')),
      content: _buildContent(context, sessionAsync, isSessionReady),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<WslSession> sessionAsync,
    bool isSessionReady,
  ) {
    return sessionAsync.when(
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => _buildError(context, error.toString()),
      data: (session) => _buildDashboard(context, session),
    );
  }

  // ======== Error State ========

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoBar(
              title: const Text('Component check failed'),
              content: Text(message),
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(sessionProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ======== Dashboard Content ========

  Widget _buildDashboard(BuildContext context, WslSession session) {
    if (!session.isRunning) {
      return _buildNoSession(context);
    }
    return _buildSessionActive(context, session);
  }

  /// When components are available but no session is created
  Widget _buildNoSession(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Center(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const Icon(FluentIcons.status_error_full, size: 64),
            Text('No active session', style: theme.typography.title),
            Text(
              'Create a WSL Container session to get started.',
              style: theme.typography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _showCreateDialog(context),
              child: const Text('Create Session'),
            ),
          ],
        ),
      ),
    );
  }

  /// When session is active
  Widget _buildSessionActive(BuildContext context, WslSession session) {
    final theme = FluentTheme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Session Status Card
        Card(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FluentIcons.status_circle_checkmark,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text('Session Active', style: theme.typography.subtitle),
                  const Spacer(),
                  _buildStopButton(context),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Version',
                session.version.isNotEmpty ? session.version : 'N/A',
              ),
              if (session.startedAt != null) ...[
                const SizedBox(height: 4),
                _buildInfoRow('Started', _formatDateTime(session.startedAt!)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Statistics Row
        Text('Statistics', style: theme.typography.subtitle),
        const SizedBox(height: 12),
        Row(
          spacing: 16,
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Images',
                session.imageCount,
                FluentIcons.box_checkmark_solid,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                context,
                'Containers',
                session.containerCount,
                FluentIcons.cube_shape,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                context,
                'Running',
                session.isRunning ? 1 : 0,
                FluentIcons.play_solid,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ======== Stat Card ========

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int value,
    IconData icon,
  ) {
    final theme = FluentTheme.of(context);
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: theme.accentColor),
          const SizedBox(height: 8),
          Text(value.toString(), style: theme.typography.titleLarge),
          Text(label, style: theme.typography.caption),
        ],
      ),
    );
  }

  // ======== Stop Button ========

  Widget _buildStopButton(BuildContext context) {
    return Button(
      onPressed: () => _confirmStopSession(context),
      child: const Text('Stop'),
    );
  }

  Future<void> _confirmStopSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Stop Session'),
        content: const Text(
          'This will stop the WSL Container session and all '
          'running containers. Continue?',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          Button(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(sessionProvider.notifier).terminateSession();
    }
  }

  // ======== Create Session Dialog ========

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ContentDialog(
          title: const Text('Create Session'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                InfoLabel(
                  label: 'Session Name',
                  child: TextBox(
                    placeholder: 'wslc_dashboard',
                    controller: _nameController,
                  ),
                ),
                InfoLabel(
                  label: 'Data Path',
                  child: TextBox(
                    placeholder: r'C:\wslc_data',
                    controller: _pathController,
                  ),
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: InfoLabel(
                        label: 'CPU Cores',
                        child: NumberBox<int>(
                          value: _cpuCount,
                          min: 1,
                          max: 32,
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => _cpuCount = v);
                            }
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: InfoLabel(
                        label: 'Memory (MB)',
                        child: NumberBox<int>(
                          value: _memoryMB,
                          min: 512,
                          max: 32768,
                          smallChange: 256,
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => _memoryMB = v);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: _isCreating ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isCreating
                  ? null
                  : () {
                      Navigator.pop(ctx, {
                        'name': _nameController.text,
                        'dataPath': _pathController.text,
                        'cpuCount': _cpuCount,
                        'memoryMB': _memoryMB,
                      });
                    },
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _isCreating = true);
      try {
        await ref
            .read(sessionProvider.notifier)
            .createSession(
              name: result['name'] as String,
              dataPath: result['dataPath'] as String,
              cpuCount: result['cpuCount'] as int,
              memoryMB: result['memoryMB'] as int,
            );
      } finally {
        if (mounted) setState(() => _isCreating = false);
      }
    }
  }

  // ======== Helpers ========

  Widget _buildInfoRow(String label, String value) {
    return SizedBox(
      width: 360,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: FluentTheme.of(context).typography.caption),
          Text(value, style: FluentTheme.of(context).typography.bodyStrong),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
