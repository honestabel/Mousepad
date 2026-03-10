import 'package:flutter/material.dart';

import '../theme/colors.dart';

class TrackpadSurface extends StatefulWidget {
  final double sensitivity;
  final void Function(double dx, double dy) onMove;
  final bool isConnected;

  const TrackpadSurface({
    super.key,
    required this.sensitivity,
    required this.onMove,
    required this.isConnected,
  });

  @override
  State<TrackpadSurface> createState() => _TrackpadSurfaceState();
}

class _TrackpadSurfaceState extends State<TrackpadSurface> {
  // Track all active pointer IDs → positions
  final Map<int, Offset> _pointers = {};
  bool _isMoving = false;

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
  }

  void _onPointerMove(PointerMoveEvent e) {
    _pointers[e.pointer] = e.position;
    // Single-touch only → relative mouse move
    // Uses PointerMoveEvent.delta for high-precision, per-frame deltas
    if (_pointers.length == 1 && widget.isConnected) {
      final dx = e.delta.dx * widget.sensitivity;
      final dy = e.delta.dy * widget.sensitivity;
      if (dx.abs() > 0.01 || dy.abs() > 0.01) {
        widget.onMove(dx, dy);
        if (!_isMoving) setState(() => _isMoving = true);
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.isEmpty && _isMoving) setState(() => _isMoving = false);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.isEmpty && _isMoving) setState(() => _isMoving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _DotGridPainter(
              isConnected: widget.isConnected,
              isActive: _isMoving,
            ),
          ),
          if (!widget.isConnected) _disconnectedHint(),
          if (_isMoving)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _disconnectedHint() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mouse_outlined,
              color: AppColors.textSecondary.withValues(alpha: 0.22),
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              'TAP  ⚙  TO CONNECT',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.28),
                fontSize: 13,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

class _DotGridPainter extends CustomPainter {
  final bool isConnected;
  final bool isActive;

  const _DotGridPainter({required this.isConnected, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final dotColor = isConnected
        ? AppColors.accent.withValues(alpha: isActive ? 0.10 : 0.055)
        : AppColors.textSecondary.withValues(alpha: 0.04);

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const r = 1.2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), r, dotPaint);
      }
    }

    if (isActive && isConnected) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) =>
      old.isConnected != isConnected || old.isActive != isActive;
}
