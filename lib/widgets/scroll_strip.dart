import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';

class ScrollStrip extends StatefulWidget {
  final double scrollSpeed;
  final bool naturalScroll;

  /// Called with whole-number tick counts (positive = down, negative = up)
  /// unless [naturalScroll] is true, in which case the direction is inverted.
  final void Function(int ticks) onScroll;

  const ScrollStrip({
    super.key,
    required this.scrollSpeed,
    required this.naturalScroll,
    required this.onScroll,
  });

  @override
  State<ScrollStrip> createState() => _ScrollStripState();
}

class _ScrollStripState extends State<ScrollStrip> {
  bool _active = false;
  double _accum = 0;

  // Logical pixels of drag required to fire one scroll tick
  static const _tickPx = 10.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (_) {
        _accum = 0;
        setState(() => _active = true);
        HapticFeedback.selectionClick();
      },
      onVerticalDragUpdate: (d) {
        _accum += d.delta.dy * widget.scrollSpeed;
        final ticks = (_accum / _tickPx).truncate();
        if (ticks != 0) {
          final direction = widget.naturalScroll ? ticks : -ticks;
          widget.onScroll(direction);
          _accum -= ticks * _tickPx;
          HapticFeedback.selectionClick();
        }
      },
      onVerticalDragEnd: (_) {
        _accum = 0;
        setState(() => _active = false);
      },
      onVerticalDragCancel: () {
        _accum = 0;
        setState(() => _active = false);
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.scrollArea,
          border: Border(
            top: BorderSide(
              color: AppColors.connected.withValues(alpha: _active ? 0.4 : 0.12),
              width: 1,
            ),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _arrow(Icons.keyboard_arrow_up),
                const SizedBox(height: 5),
                ..._lines(),
                const SizedBox(height: 5),
                _arrow(Icons.keyboard_arrow_down),
              ],
            ),
            Positioned(
              bottom: 7,
              child: Text(
                'SCROLL',
                style: TextStyle(
                  color: AppColors.connected.withValues(alpha: 0.22),
                  fontSize: 7.5,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrow(IconData icon) => Icon(
        icon,
        size: 18,
        color: AppColors.connected.withValues(alpha: _active ? 0.65 : 0.2),
      );

  List<Widget> _lines() => List.generate(5, (i) {
        final mid = i == 2;
        final near = i == 1 || i == 3;
        final opacity = _active
            ? (mid ? 0.85 : near ? 0.55 : 0.28)
            : (mid ? 0.32 : near ? 0.16 : 0.07);
        final width = mid ? 44.0 : near ? 30.0 : 18.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: width,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.connected.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      });
}
