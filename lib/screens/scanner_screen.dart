import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visitor_management/providers/visitor_providers.dart';

import '../core/app_exception.dart';
import 'visitor_details_screen.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  static final RegExp _validId = RegExp(r'^[A-Za-z0-9_-]+$');

  bool _isProcessing = false;
  String? _error;
  String? _lastHandledId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final raw =
        capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final id = raw?.trim();

    // Ignore stale replays delivered by mobile_scanner immediately after
    // stop()/start(), which are the #1 cause of "wrong visitor" bugs.
    if (id == null || id == _lastHandledId) return;

    _isProcessing = true;
    _lastHandledId = id;

    try {
      if (!_validId.hasMatch(id)) {
        _showError('Invalid QR code. Please scan a visitor QR code.');
      } else {
        // 1. Fetch authoritative visitor for this id
final visitor = await ref.read(visitorServiceProvider).fetchVisitorById(id);

        // 2. Defensive check: if the API returns a visitor with a
        //    mismatched id, we must not show wrong details.
        if (visitor.id != id) {
          throw AppException(
            'API returned mismatched visitor (asked $id, got ${visitor.id})',
          );
        }

        // 3. Make sure it's in the local list for other screens
        await ref.read(visitorsProvider.notifier).upsert(visitor);

        if (!mounted) return;
        setState(() => _error = null);

        await _controller.stop();
        if (!mounted) return;

        // 4. Pass BOTH the id and the object so details is always correct
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VisitorDetailsScreen(
              visitorId: visitor.id,
              initialVisitor: visitor,
            ),
          ),
        );
        if (!mounted) return;
        await _controller.start();
      }
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isProcessing = false;
      _lastHandledId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraErrorView(error: error),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _error == null ? Colors.black87 : Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error ?? 'Point the camera at a visitor QR code',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error});

  final MobileScannerException error;

  String get _message {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission is denied. Allow camera access in the '
            'app settings and try again.';
      case MobileScannerErrorCode.unsupported:
        return 'Scanning is not supported on this device. '
            'Use a real Android or iOS phone.';
      default:
        return 'The camera could not be started. Close other apps that '
            'use the camera and try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Camera error code: ${error.errorCode}');
    debugPrint('Camera error details: $error');

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography, color: Colors.white, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Camera not available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            _message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Code: ${error.errorCode.name}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}