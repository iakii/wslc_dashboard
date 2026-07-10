import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 镜像管理页面
class ImagesPage extends ConsumerWidget {
  const ImagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('镜像管理')),
      content: Center(
        child: Text(
          '镜像列表 + 拉取/删除',
          style: FluentTheme.of(context).typography.bodyLarge,
        ),
      ),
    );
  }
}
