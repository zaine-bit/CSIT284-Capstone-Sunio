import 'package:flutter/material.dart';

/// Fade + slide-up for one time window of an AnimationController.
/// Use different start/end values to stagger things.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
  });

  final Animation<double> controller;
  final double start; // 0.0 - 1.0
  final double end; // 0.0 - 1.0
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
