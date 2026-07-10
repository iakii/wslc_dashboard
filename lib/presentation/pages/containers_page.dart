import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 容器管理页面
class ContainersPage extends ConsumerWidget {
  const ContainersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('容器管理')),
      content: Center(
        child: Text(
          '容器列表 + 创建/启停/删除',
          style: FluentTheme.of(context).typography.bodyLarge,
        ),
      ),
    );
  }
}
