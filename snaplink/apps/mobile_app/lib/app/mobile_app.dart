import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'mobile_router.dart';

class SnaplinkMobileApp extends StatelessWidget {
  const SnaplinkMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SNAPLINK',
      theme: SnaplinkTheme.light(),
      routerConfig: buildMobileRouter(),
    );
  }
}

