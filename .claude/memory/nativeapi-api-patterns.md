---
name: nativeapi-api-patterns
description: nativeapi Flutter package 核心 API 使用模式
metadata:
  type: reference
---

## nativeapi 核心 API

### WindowManager
```dart
final wm = WindowManager.instance;
final window = wm.getCurrent();    // 获取当前窗口
window?.show(); window?.hide(); window?.center(); window?.focus();
window?.title = '...';
window?.titleBarStyle = TitleBarStyle.hidden;  // 或 .normal
window?.setSize(w, h);
window?.setMinimumSize(w, h);
window?.setPosition(x, y);
// 关闭拦截
wm.setWillHideHook((windowId) => false);  // return false 阻止关闭
// 事件监听
wm.addListener<WindowFocusedEvent>((e) => print(e.windowId));
```

### TrayIcon
```dart
final tray = TrayIcon();
tray.icon = Image.fromAsset('assets/tray.png');  // nativeapi::Image，非 Flutter Image
tray.tooltip = '...';
tray.contextMenu = Menu()
  ..addItem(MenuItem('显示窗口'))
  ..addSeparator()
  ..addItem(MenuItem('退出'));
tray.contextMenuTrigger = ContextMenuTrigger.rightClicked;
tray.on<TrayIconClickedEvent>((e) => window?.show());
// MenuItem 事件
final item = MenuItem('显示窗口');
item.on<MenuItemClickedEvent>((e) => window?.show());
```

### Menu & MenuItem
```dart
final menu = Menu();
menu.addItem(MenuItem('label'));              // 位置参数，非命名参数
menu.addItem(MenuItem('label', MenuItemType.separator));  // 分隔符
menu.addSeparator();                           // 或直接用此法
```

### Preferences (字符串值)
```dart
final prefs = Preferences();
prefs.set('key', 'string_value');            // 只支持 String
final val = prefs.get('key', 'default');      // 返回 String
prefs.dispose();
```

### LaunchAtLogin (开机自启动)
```dart
final lal = LaunchAtLogin(id: 'app_id', displayName: 'My App');
lal.setProgram(executablePath, arguments);
lal.enable();  // bool
lal.disable();
lal.isEnabled;  // bool
```

### UrlOpener
```dart
UrlOpener.instance.open('https://...');
```

### 命名冲突处理
```dart
import 'package:nativeapi/nativeapi.dart' hide Image;
import 'package:nativeapi/nativeapi.dart' as nativeapi;
// nativeapi::Image 通过 nativeapi.Image.fromAsset(...) 访问
```
