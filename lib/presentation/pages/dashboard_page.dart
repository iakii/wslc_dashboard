import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/wsl_session.dart';
import '../../domain/entities/wsl_session_info.dart';
import '../providers/session_providers.dart';

/// WSL Session overview page — session selector + status card + statistics
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // ======== Create Session Dialog Fields ========
  final _nameController = TextEditingController(text: AppConstants.defaultSessionName);
  final _pathController = TextEditingController(text: AppConstants.defaultDataPath);
  int _cpuCount = 0; // 0 = system default
  int _memoryMB = 0; // 0 = system default

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
    final sessionListAsync = ref.watch(sessionListProvider);
    final selectedName = ref.watch(selectedSessionNameProvider);

    return ScaffoldPage(
      header: const PageHeader(title: Text('概览')),
      content: Column(
        children: [
          // Session 选择器（顶部栏）
          _buildSessionSelector(context, sessionListAsync, selectedName),
          const Divider(),
          // Session 详情（下方主区域）
          Expanded(child: _buildContent(context, sessionAsync)),
        ],
      ),
    );
  }

  // ============================================================
  // Session 选择器
  // ============================================================

  Widget _buildSessionSelector(
    BuildContext context,
    AsyncValue<List<WslSessionInfo>> sessionListAsync,
    String selectedName,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        spacing: 12,
        children: [
          // Session 下拉选择
          const Text('Session:'),
          SizedBox(
            width: 220,
            child: sessionListAsync.when(
              loading: () => const ComboBox<String>(
                items: [],
                placeholder: Text('加载中…'),
              ),
              error: (_, _) => ComboBox<String>(
                value: selectedName,
                items: [ComboBoxItem(value: selectedName, child: Text(selectedName))],
                onChanged: null,
              ),
              data: (sessions) {
                final items = sessions
                    .map((s) => ComboBoxItem<String>(
                          value: s.displayName,
                          child: Text(s.displayName),
                        ))
                    .toList();
                // 确保当前选中值在列表中
                if (!sessions.any((s) => s.displayName == selectedName)) {
                  items.insert(
                    0,
                    ComboBoxItem(value: selectedName, child: Text(selectedName)),
                  );
                }
                return ComboBox<String>(
                  value: selectedName,
                  items: items,
                  onChanged: (name) {
                    if (name != null && name != selectedName) {
                      _onSessionSelected(name);
                    }
                  },
                );
              },
            ),
          ),

          // 刷新按钮
          IconButton(
            icon: const Icon(FluentIcons.refresh, size: 18),
            onPressed: () => ref.invalidate(sessionListProvider),
          ),

          // 新建按钮
          IconButton(
            icon: const Icon(FluentIcons.add, size: 18),
            onPressed: () => _showCreateDialog(context),
          ),

          const Spacer(),

          // 当前 session 类型标记
          sessionListAsync.whenOrNull(
            data: (sessions) {
              final current = sessions.where((s) => s.displayName == selectedName);
              if (current.isEmpty) return const SizedBox.shrink();
              final managed = current.first.isManagedByDashboard;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: managed
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  managed ? 'Dashboard 管理' : 'CLI 管理（只读）',
                  style: TextStyle(
                    fontSize: 11,
                    color: managed ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  /// Session 切换处理
  void _onSessionSelected(String name) {
    final sessions = ref.read(sessionListProvider).valueOrNull ?? [];
    final target = sessions.where((s) => s.displayName == name);

    if (target.isNotEmpty && !target.first.isManagedByDashboard) {
      // CLI session — 无法操作，仅更新选中状态
      ref.read(selectedSessionNameProvider.notifier).state = name;
      return;
    }

    // Dashboard session — 切换到该 session
    ref.read(sessionProvider.notifier).switchToSession(name);
  }

  // ============================================================
  // 主内容区
  // ============================================================

  Widget _buildContent(BuildContext context, AsyncValue<WslSession> sessionAsync) {
    return sessionAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            ProgressRing(),
            Text('正在连接 Session…'),
          ],
        ),
      ),
      error: (error, stack) => _buildError(context, error.toString()),
      data: (session) => _buildDashboard(context, session),
    );
  }

  // ============================================================
  // Error State
  // ============================================================

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoBar(
              title: const Text('Session 连接失败'),
              content: Text(message),
              severity: InfoBarSeverity.error,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => ref.read(sessionProvider.notifier).refresh(),
                  child: const Text('重试'),
                ),
                Button(
                  onPressed: () => _showCreateDialog(context),
                  child: const Text('手动创建…'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Dashboard Content
  // ============================================================

  Widget _buildDashboard(BuildContext context, WslSession session) {
    if (!session.isRunning) {
      return _buildNoSession(context);
    }
    return _buildSessionActive(context, session);
  }

  /// Session 已终止或未创建
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
            Text('Session 已终止', style: theme.typography.title),
            Text(
              '当前没有活动的 WSL 容器 Session。',
              style: theme.typography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                // 自动使用默认配置重新创建
                FilledButton(
                  onPressed: () async {
                    ref.read(sessionProvider.notifier).createSession(
                          name: AppConstants.defaultSessionName,
                          dataPath: AppConstants.defaultDataPath,
                          cpuCount: AppConstants.defaultCpuCount,
                          memoryMB: AppConstants.defaultMemoryMB,
                        );
                  },
                  child: const Text('重新创建默认 Session'),
                ),
                // 可选：手动指定配置
                Button(
                  onPressed: () => _showCreateDialog(context),
                  child: const Text('自定义创建…'),
                ),
              ],
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
                    placeholder: AppConstants.defaultSessionName,
                    controller: _nameController,
                  ),
                ),
                InfoLabel(
                  label: 'Data Path',
                  child: TextBox(
                    placeholder: AppConstants.defaultDataPath,
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
