import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_exception.dart';
import '../models/visitor.dart';
import '../providers/visitor_providers.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/visitor_card.dart';
import 'visitor_details_screen.dart';
import 'visitor_register_screen.dart';

class VisitorListScreen extends ConsumerStatefulWidget {
  const VisitorListScreen({super.key});

  @override
  ConsumerState<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends ConsumerState<VisitorListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(searchQueryProvider));
    // Ensure fresh data from the API whenever the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visitorsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _confirmDelete(Visitor visitor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete visitor?'),
        content: Text(
          'Are you sure you want to delete ${visitor.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(visitorsProvider.notifier).deleteVisitor(visitor.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(appSnackBar('Visitor deleted'));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(appSnackBar(e.message, isError: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitors = ref.watch(filteredVisitorsProvider);
    final query = ref.watch(searchQueryProvider).trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Visitors')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name or mobile number',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          ),
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: visitors.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: errorMessage(error),
                  onRetry: () =>
                      ref.read(visitorsProvider.notifier).refresh(),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.people_outline,
                      message: query.isEmpty
                          ? 'No visitor records'
                          : 'No visitors',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final visitor = list[index];
                      return VisitorCard(
                        visitor: visitor,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                VisitorDetailsScreen(visitorId: visitor.id),
                          ),
                        ),
                        onEdit: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                VisitorRegisterScreen(visitor: visitor),
                          ),
                        ),
                        onDelete: () => _confirmDelete(visitor),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}