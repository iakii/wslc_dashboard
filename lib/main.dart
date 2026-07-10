import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 使用 hide flutter_widgets_Image 解决与 nativeapi::Image 的命名冲突
import 'package:nativeapi/nativeapi.dart' as nativeapi;
import 'package:nativeapi/nativeapi.dart' hide Image;

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ======== 窗口初始化 ========
  final windowManager = WindowManager.instance;
  final window = windowManager.getCurrent();
  window?.backgroundColor = Colors.transparent;
  window?.titleBarStyle = TitleBarStyle.hidden;
  window?.visualEffect = .mica;
  window?.show();
  window?.center();

  // ======== 关闭前拦截 — 最小化到托盘 ========
  windowManager.setWillHideHook((windowId) {
    // 返回 false 阻止窗口真正关闭/隐藏
    // 用户点击关闭时窗口残留，后续 trayIcon 恢复
    return false;
  });

  // ======== 系统托盘 ========
  _setupTray(window);

  // ======== 运行应用 ========
  runApp(const ProviderScope(child: WslcDashboardApp()));
}

/// 设置系统托盘
void _setupTray(Window? window) {
  final trayIcon = TrayIcon();
  final iconImage = nativeapi.Image.fromAsset('assets/tray.png');
  if (iconImage != null) {
    trayIcon.icon = iconImage;
  }
  trayIcon.tooltip = 'WSL Container Dashboard';

  // 构建托盘菜单
  final menu = Menu();
  final showItem = MenuItem('显示窗口');
  showItem.on<MenuItemClickedEvent>((event) {
    window?.show();
    window?.focus();
  });
  menu.addItem(showItem);
  menu.addSeparator();
  final exitItem = MenuItem('退出');
  exitItem.on<MenuItemClickedEvent>((event) {
    SystemNavigator.pop();
  });
  menu.addItem(exitItem);

  trayIcon.contextMenu = menu;
  trayIcon.contextMenuTrigger = ContextMenuTrigger.rightClicked;
  trayIcon.on<TrayIconClickedEvent>((event) {
    window?.show();
    window?.focus();
  });
}
