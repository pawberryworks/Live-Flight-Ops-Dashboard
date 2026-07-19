import 'dart:async';

import 'package:flutter/material.dart';

/// A short-lived notification for failures returned by the dashboard backend.
class BackendErrorPopup extends StatefulWidget {
  const BackendErrorPopup({
    required this.error,
    required this.onDismiss,
    super.key,
  });

  final Object error;
  final VoidCallback onDismiss;

  @override
  State<BackendErrorPopup> createState() => _BackendErrorPopupState();
}

class _BackendErrorPopupState extends State<BackendErrorPopup> {
  late final Timer _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 6), widget.onDismiss);
  }

  @override
  void dispose() {
    _dismissTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Semantics(
        liveRegion: true,
        label: 'Backend error',
        child: Container(
          key: const ValueKey('backend-error-popup'),
          width: 360,
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(blurRadius: 16, color: Color(0x33000000)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend error',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unable to complete the request. Please try again. '
                      '(${widget.error})',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss backend error',
                onPressed: widget.onDismiss,
                icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
