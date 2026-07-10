import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 概览页面 — Session 状态 + 快速统计
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('概览')),
      content: Center(
        child: Text(
          'Dashboard — Session 状态卡片 & 统计',
          style: FluentTheme.of(context).typography.bodyLarge,
        ),
      ),
    );
  }
}
