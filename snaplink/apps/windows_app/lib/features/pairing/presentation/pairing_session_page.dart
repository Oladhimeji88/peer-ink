import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:windows_app/core/providers/app_providers.dart';

class PairingSessionPage extends ConsumerWidget {
  const PairingSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listenerState = ref.watch(desktopListenerStateProvider);

    return listenerState.when(
      data: (state) {
        final session = state.pairingSession;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SectionCard(
                title: 'Pairing QR',
                subtitle: 'Scan once from the mobile app to establish trust.',
                actions: <Widget>[
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.read(pairingControllerProvider).regenerateQr(),
                    child: const Text('Regenerate'),
                  ),
                ],
                child: session == null || state.qrPayload == null
                    ? const Text('No active pairing session.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: QrImageView(
                                  data: state.qrPayload!,
                                  size: 280,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF12212F),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Session ID: ${session.sessionId}'),
                          Text('Expires at: ${session.expiresAt.toLocal()}'),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SectionCard(
                title: 'Session Details',
                subtitle: 'Protocol and server details included in the QR payload.',
                child: session == null
                    ? const Text('No session available.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Desktop: ${session.desktopName}'),
                          Text('Listener Port: ${session.port}'),
                          Text('One-time Token Used: ${session.used}'),
                          Text(
                            'Expires in: ${session.expiresAt.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 60)}s',
                          ),
                          const SizedBox(height: 18),
                          StatusBadge(label: state.status.name),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
      error: (Object error, StackTrace stackTrace) => Text('$error'),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
