import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:windows_app/app/windows_router.dart';

class SnaplinkDesktopApp extends StatelessWidget {
  const SnaplinkDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SNAPLINK',
      theme: SnaplinkTheme.light(),
      routerConfig: buildWindowsRouter(),
    );
  }
}

