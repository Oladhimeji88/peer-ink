import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile_app/features/camera_capture/presentation/camera_capture_page.dart';
import 'package:mobile_app/features/connect/presentation/connect_page.dart';
import 'package:mobile_app/features/onboarding/presentation/onboarding_page.dart';
import 'package:mobile_app/features/qr_scan/presentation/qr_scan_page.dart';
import 'package:mobile_app/features/settings/presentation/settings_page.dart';
import 'package:mobile_app/features/transfer_history/presentation/transfer_history_page.dart';
import 'package:mobile_app/features/trusted_devices/presentation/trusted_devices_page.dart';

GoRouter buildMobileRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/connect', builder: (_, __) => const ConnectPage()),
      GoRoute(path: '/scan', builder: (_, __) => const QrScanPage()),
      GoRoute(path: '/camera', builder: (_, __) => const CameraCapturePage()),
      GoRoute(path: '/history', builder: (_, __) => const TransferHistoryPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(
        path: '/trusted-devices',
        builder: (_, __) => const TrustedDevicesPage(),
      ),
    ],
  );
}
