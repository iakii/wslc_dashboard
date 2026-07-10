import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/containers_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/images_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/providers/settings_providers.dart';

/// WSL Container Dashboard 根组件
class WslcDashboardApp extends ConsumerWidget {
  const WslcDashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkThemeProvider);

    return FluentApp(
      title: 'WSL Container Dashboard',
      theme: isDark ? AppTheme.dark() : AppTheme.light(),
      home: const _NavigationShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 导航壳
class _NavigationShell extends StatefulWidget {
  const _NavigationShell();

  @override
  State<_NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<_NavigationShell> {
  int _selectedIndex = 0;

  /// 页面列表
  final List<Widget> _pages = const [
    DashboardPage(),
    ImagesPage(),
    ContainersPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('概览'),
            body: _pages[0],
          ),
          PaneItem(
            icon: const Icon(FluentIcons.box_checkmark_solid),
            title: const Text('镜像'),
            body: _pages[1],
          ),
          PaneItem(
            icon: const Icon(FluentIcons.cube_shape),
            title: const Text('容器'),
            body: _pages[2],
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('设置'),
            body: _pages[3],
          ),
        ],
      ),
    );
  }
}
