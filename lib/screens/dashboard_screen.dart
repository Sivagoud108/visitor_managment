import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_exception.dart';
import '../providers/visitor_providers.dart';
import '../widgets/custom_button.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'visitor_register_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitors = ref.watch(visitorsProvider);
    final stats = ref.watch(dashboardStatsProvider);

    final cards = [
      DashboardStatCard(
        title: 'Total Visitors Today',
        value: stats.totalToday,
        icon: Icons.groups,
        color: Colors.indigo,
      ),
      DashboardStatCard(
        title: 'Currently Checked In',
        value: stats.checkedIn,
        icon: Icons.login,
        color: Colors.green,
      ),
      DashboardStatCard(
        title: 'Checked Out Today',
        value: stats.checkedOutToday,
        icon: Icons.logout,
        color: Colors.orange,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(visitorsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: visitors.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            message: errorMessage(error),
            onRetry: () => ref.read(visitorsProvider.notifier).refresh(),
          ),
          data: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 600) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final card in cards)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: card,
                              ),
                            ),
                        ],
                      );
                    }
                    return Column(children: cards);
                  },
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Register Visitor',
                  icon: Icons.person_add,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VisitorRegisterScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Visitor List',
                  icon: Icons.list_alt,
                  isOutlined: true,
                  onPressed: () =>
                      ref.read(navIndexProvider.notifier).state = 1,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Scan QR Code',
                  icon: Icons.qr_code_scanner,
                  isOutlined: true,
                  onPressed: () =>
                      ref.read(navIndexProvider.notifier).state = 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}