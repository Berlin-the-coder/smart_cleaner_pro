import 'package:flutter/material.dart';

/// Wraps any widget with a subtle scale-down-on-press animation —
/// the same kind of tactile feedback used throughout well-polished
/// native and Material apps. Deliberately implemented with a single
/// [AnimatedScale] (GPU-accelerated transform, no layout/repaint cost)
/// rather than a full [AnimationController], so it's cheap enough to
/// use freely without affecting scroll or scan performance.
///
/// Usage:
/// ```dart
/// Pressable(
///   onTap: () => doSomething(),
///   child: MyButtonOrCard(),
/// )
/// ```
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far to scale down on press. 0.96 is a subtle, professional
  /// amount — noticeable but not bouncy or distracting.
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
