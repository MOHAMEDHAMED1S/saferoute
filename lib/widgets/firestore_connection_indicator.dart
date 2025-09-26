import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firestore_connection_manager.dart';

/// Widget that shows Firestore connection status
class FirestoreConnectionIndicator extends StatefulWidget {
  final Widget child;
  final bool showIndicator;
  final Color? connectedColor;
  final Color? disconnectedColor;

  const FirestoreConnectionIndicator({
    Key? key,
    required this.child,
    this.showIndicator = true,
    this.connectedColor,
    this.disconnectedColor,
  }) : super(key: key);

  @override
  State<FirestoreConnectionIndicator> createState() =>
      _FirestoreConnectionIndicatorState();
}

class _FirestoreConnectionIndicatorState
    extends State<FirestoreConnectionIndicator> {
  late StreamSubscription<bool> _connectionSubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectionSubscription = FirestoreConnectionManager().connectionStream
        .listen((isConnected) {
          if (mounted) {
            setState(() {
              _isConnected = isConnected;
            });
          }
        });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showIndicator && !_isConnected) _buildConnectionIndicator(),
      ],
    );
  }

  Widget _buildConnectionIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.disconnectedColor ?? Colors.orange,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'وضع عدم الاتصال - البيانات المحفوظة محلياً',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await FirestoreConnectionManager().forceConnectionCheck();
              },
              child: const Icon(Icons.refresh, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple connection status widget for debugging
class FirestoreConnectionStatus extends StatelessWidget {
  const FirestoreConnectionStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FirestoreConnectionManager().connectionStream,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isConnected ? 'متصل بقاعدة البيانات' : 'غير متصل',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
