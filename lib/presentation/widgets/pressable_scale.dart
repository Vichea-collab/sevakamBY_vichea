import 'package:flutter/material.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.985,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _scale = 1.0;

  void _setScale(double value) {
    if (_scale == value) return;
    setState(() => _scale = value);
  }

  void _onPressDown() {
    if (widget.onTap == null) return;
    _setScale(widget.pressedScale);
  }

  void _onPressEnd() {
    if (widget.onTap == null) return;
    _setScale(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onPressDown(),
      onPointerUp: (_) => _onPressEnd(),
      onPointerCancel: (_) => _onPressEnd(),
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}
