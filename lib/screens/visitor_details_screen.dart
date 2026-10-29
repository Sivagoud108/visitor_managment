import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_exception.dart';
import '../core/date.dart';
import '../models/visitor.dart';
import '../providers/visitor_providers.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/status_chip.dart';

class VisitorDetailsScreen extends ConsumerStatefulWidget {
  const VisitorDetailsScreen({
    super.key,
    required this.visitorId,
    this.initialVisitor,
  });

  final String visitorId;
  final Visitor? initialVisitor;

  @override
  ConsumerState<VisitorDetailsScreen> createState() =>
      _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends ConsumerState<VisitorDetailsScreen> {
  bool _isUpdating = false;

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(appSnackBar(successMessage));
      ref.invalidate(visitorByIdProvider(widget.visitorId));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(appSnackBar(e.message, isError: true));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) { 
    final asyncVisitor = ref.watch(visitorByIdProvider(widget.visitorId));
    final notifier = ref.read(visitorsProvider.notifier);

    // Immediate fallback while API fetch is in flight.
    if (asyncVisitor.isLoading && widget.initialVisitor != null) {
      return _scaffold(_buildContent(widget.initialVisitor!, notifier));
    }

    return _scaffold(
      asyncVisitor.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: errorMessage(error),
          onRetry: () => ref.invalidate(visitorByIdProvider(widget.visitorId)),
        ),
        data: (visitor) => _buildContent(visitor, notifier),
      ),
    );
  }

  Widget _scaffold(Widget body) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Details')),
      body: SafeArea(child: body),
    );
  }

  Widget _buildContent(Visitor visitor, VisitorsNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          visitor.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      StatusChip(status: visitor.status),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: 'Visitor ID', value: visitor.id),
                  _InfoRow(label: 'Name', value: visitor.name),
                  _InfoRow(label: 'Mobile', value: visitor.mobile),
                  if (visitor.email != null)
                    _InfoRow(label: 'Email', value: visitor.email!),
                  _InfoRow(label: 'Visitor Type', value: visitor.visitorType),
                  _InfoRow(label: 'Project', value: visitor.project),
                  _InfoRow(label: 'Purpose', value: visitor.purpose),
                  _InfoRow(
                    label: 'Registered',
                    value: formatDateTime(visitor.createdAt),
                  ),
                  if (visitor.checkInTime != null)
                    _InfoRow(
                      label: 'Check-in',
                      value: formatDateTime(visitor.checkInTime!),
                    ),
                  if (visitor.checkOutTime != null)
                    _InfoRow(
                      label: 'Check-out',
                      value: formatDateTime(visitor.checkOutTime!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: QrImageView(
                      data: visitor.id,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan this QR code to identify the visitor',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (visitor.canCheckIn)
            CustomButton(
              label: 'Check In',
              icon: Icons.login,
              isLoading: _isUpdating,
              onPressed: () => _runAction(
                () => notifier.checkIn(visitor.id),
                'Visitor checked in',
              ),
            )
          else if (visitor.canCheckOut)
            CustomButton(
              label: 'Check Out',
              icon: Icons.logout,
              isLoading: _isUpdating,
              onPressed: () => _runAction(
                () => notifier.checkOut(visitor.id),
                'Visitor checked out',
              ),
            )
          else
            Center(
              child: Text(
                'Visit completed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}