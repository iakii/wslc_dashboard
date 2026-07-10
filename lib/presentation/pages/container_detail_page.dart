import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 容器详情页 — 日志终端
class ContainerDetailPage extends ConsumerWidget {
  const ContainerDetailPage({super.key, required this.containerId});

  final String containerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text('容器详情 — $containerId'),
        commandBar: Row(mainAxisSize: MainAxisSize.min, children: [
          FilledButton(
            child: const Text('启动'),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Button(
            child: const Text('停止'),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Button(
            child: const Text('删除'),
            onPressed: () {},
          ),
        ]),
      ),
      content: Center(
        child: Text(
          '日志终端 — 实时 stdout/stderr',
          style: FluentTheme.of(context).typography.bodyLarge,
        ),
      ),
    );
  }
}
