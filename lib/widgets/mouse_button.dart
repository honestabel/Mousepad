import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MouseButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;

  const MouseButton({
    super.key,
    required this.label,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<MouseButton> createState() => _MouseButtonState();
}

class _MouseButtonState extends State<MouseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
    reverseDuration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.95).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
  );
  bool _pressed = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) {
    setState(() => _pressed = true);
    _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  void _up(_) {
    setState(() => _pressed = false);
    _ctrl.reverse();
    widget.onTap();
  }

  void _cancel() {
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _pressed
                ? widget.accentColor.withValues(alpha: 0.18)
                : widget.color,
            border: Border(
              top: BorderSide(
                color: widget.accentColor.withValues(alpha: _pressed ? 0.5 : 0.15),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mouse_outlined,
                color: widget.accentColor.withValues(alpha: _pressed ? 0.75 : 0.4),
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                widget.label,
                style: TextStyle(
                  color:
                      widget.accentColor.withValues(alpha: _pressed ? 1.0 : 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'CLICK',
                style: TextStyle(
                  color: widget.accentColor.withValues(alpha: 0.3),
                  fontSize: 8,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
