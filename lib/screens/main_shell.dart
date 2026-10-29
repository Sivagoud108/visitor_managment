import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visitor_management/providers/visitor_providers.dart';
import 'package:visitor_management/screens/dashboard_screen.dart';
import 'scanner_screen.dart';
import 'visitor_list_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navIndexProvider);

    final Widget child;
    switch (index) {
      case 0:
        child = const DashboardScreen();

        break;
      case 1:
        child = const VisitorListScreen();

        break;
      default:

        child = const ScannerScreen();
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _FloatingNavigationBar(
        selectedIndex: index,
        onSelected: (i) => ref.read(navIndexProvider.notifier).state = i,
      ),
    );
  }
}

/// Rounded navigation bar that floats above the page with a soft shadow.
class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: primary.withAlpha(30),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: primary),
              label: 'Visitors',
            ),
            NavigationDestination(
              icon: const Icon(Icons.qr_code_scanner),
              selectedIcon: Icon(Icons.qr_code_scanner, color: primary),
              label: 'Scan',
            ),
          ],
        ),
      ),
    );
  }
}