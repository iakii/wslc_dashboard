import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('设置')),
      content: Center(
        child: Text(
          'Session 配置 / 自启动 / 托盘 / 主题',
          style: FluentTheme.of(context).typography.bodyLarge,
        ),
      ),
    );
  }
}
