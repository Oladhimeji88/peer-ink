import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import '../core/providers/app_providers.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/gallery/presentation/gallery_page.dart';
import '../features/logs/presentation/logs_page.dart';
import '../features/pairing/presentation/pairing_session_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/trusted_devices/presentation/trusted_devices_page.dart';

GoRouter buildWindowsRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return _DesktopShellFrame(
            location: state.uri.toString(),
            child: child,
          );
        },
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/pairing', builder: (_, __) => const PairingSessionPage()),
          GoRoute(path: '/gallery', builder: (_, __) => const GalleryPage()),
          GoRoute(
            path: '/trusted-devices',
            builder: (_, __) => const TrustedDevicesPage(),
          ),
          GoRoute(path: '/logs', builder: (_, __) => const LogsPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );
}

class _DesktopShellFrame extends ConsumerWidget {
  const _DesktopShellFrame({
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  static const List<String> _locations = <String>[
    '/',
    '/pairing',
    '/gallery',
    '/trusted-devices',
    '/logs',
    '/settings',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listenerState = ref.watch(desktopListenerStateProvider);
    final selectedIndex =
        _locations.indexOf(location).clamp(0, _locations.length - 1) as int;
    final status = listenerState.valueOrNull?.status.name ?? 'booting';

    return DesktopShell(
      navigationRailDestinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.qr_code_2_outlined),
          selectedIcon: Icon(Icons.qr_code_2_rounded),
          label: Text('Pair'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library_rounded),
          label: Text('Gallery'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.devices_other_outlined),
          selectedIcon: Icon(Icons.devices_other_rounded),
          label: Text('Trusted'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: Text('Logs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune_rounded),
          label: Text('Settings'),
        ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: (int index) => context.go(_locations[index]),
      title: 'SNAPLINK Console',
      statusLabel: status,
      child: child,
    );
  }
}
