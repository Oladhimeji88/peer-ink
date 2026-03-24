import 'package:flutter/material.dart';

import '../widgets/status_badge.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({
    required this.navigationRailDestinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.title,
    required this.statusLabel,
    required this.child,
    super.key,
  });

  final List<NavigationRailDestination> navigationRailDestinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String title;
  final String statusLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          Container(
            width: 104,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Colors.white),
              selectedLabelTextStyle: const TextStyle(color: Colors.white),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              unselectedLabelTextStyle:
                  const TextStyle(color: Colors.white70),
              destinations: navigationRailDestinations,
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        StatusBadge(label: statusLabel),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

