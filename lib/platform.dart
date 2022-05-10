library widgets;

import 'dart:io' as io;

import 'package:flutter/widgets.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Platform {
  mac,
  ios,
  android,
  windows,
  linux,
  fallback,
}

class PlatformBundle {
  final Widget application;
  final Future<void> Function()? preRun;
  final List<Override> overrides;

  const PlatformBundle({
    required this.application,
    this.preRun,
    this.overrides = const [],
  });

  static Future<void> Function() genericMacOSPreRun({
    double width = 800,
    double height = 600,
    String title = '',
    bool closable = true,
    bool alwaysOnTop = false,
    bool hideTitleBar = false,
    bool skipTaskbar = false,
    Future<void> Function()? initRest,
    String? systemTrayIcon,
    List<MenuItem>? systemTrayMenu,
  }) {
    return () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Window Manager
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow().then((_) async {
        await windowManager.setTitleBarStyle(
          hideTitleBar ? TitleBarStyle.hidden : TitleBarStyle.normal,
        );
        await windowManager.setTitle(title);
        await windowManager.setSize(Size(width, height));
        await windowManager.setClosable(closable);
        await windowManager.setAlwaysOnTop(alwaysOnTop);
        await windowManager.setSkipTaskbar(skipTaskbar);
        if (initRest != null) {
          initRest();
        }
        await windowManager.show();
      });

      // System Tray
      if (systemTrayIcon != null) {
        await trayManager.setIcon(systemTrayIcon);
      }
      if (systemTrayMenu != null) {
        await trayManager.setContextMenu(
          Menu(
            items: systemTrayMenu,
          ),
        );
      }
    };
  }
}

PlatformBundle getBundle(Map<Platform, PlatformBundle> mapping) {
  if (io.Platform.isMacOS) {
    return mapping[Platform.mac] ?? mapping[Platform.fallback]!;
  } else if (io.Platform.isIOS) {
    return mapping[Platform.ios] ?? mapping[Platform.fallback]!;
  } else if (io.Platform.isAndroid) {
    return mapping[Platform.android] ?? mapping[Platform.fallback]!;
  } else if (io.Platform.isWindows) {
    return mapping[Platform.windows] ?? mapping[Platform.fallback]!;
  } else if (io.Platform.isLinux) {
    return mapping[Platform.linux] ?? mapping[Platform.fallback]!;
  } else {
    return mapping[Platform.fallback]!;
  }
}

Future<void> runPlatformApp(Map<Platform, PlatformBundle> mapping) async {
  final bundle = getBundle(mapping);

  // Pre run
  if (bundle.preRun != null) {
    await bundle.preRun!();
  }

  // Run app
  runApp(
    ProviderScope(
      overrides: bundle.overrides,
      child: bundle.application,
    ),
  );
}
