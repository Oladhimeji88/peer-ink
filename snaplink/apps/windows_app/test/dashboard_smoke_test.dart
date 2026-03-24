import 'package:core_protocol/core_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:windows_app/core/models/desktop_listener_state.dart';
import 'package:windows_app/core/providers/app_providers.dart';
import 'package:windows_app/features/dashboard/presentation/dashboard_page.dart';

void main() {
  testWidgets('dashboard renders receive sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          desktopListenerStateProvider.overrideWith(
            (Ref ref) => Stream<DesktopListenerState>.value(
              DesktopListenerState.initial().copyWith(
                status: AppConnectionStatus.waitingForScan,
              ),
            ),
          ),
          galleryDataProvider.overrideWith(
            (Ref ref) => Stream<List<TransferResult>>.value(const <TransferResult>[]),
          ),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Latest Received Photos'), findsOneWidget);
  });
}

