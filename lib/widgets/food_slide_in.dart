import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One food picture that slides in from the left or right edge.
class FoodSprite {
  const FoodSprite({
    required this.asset,
    required this.alignment,
    required this.size,
    required this.fromLeft,
    required this.start,
    required this.end,
    this.phase = 0,
  });

  final String asset; // e.g. 'assets/images/food_1.png'
  final Alignment alignment; // where it ends up: (-1,-1) top-left ... (1,1) bottom-right
  final double size; // width/height in px
  final bool fromLeft; // true = enters from the left edge, false = from the right
  final double start; // when it starts sliding (0.0 - 1.0 of the intro animation)
  final double end; // when it lands (0.0 - 1.0)
  final double phase; // offsets the gentle up/down bobbing (0.0 - 1.0)
}

/// EDIT THIS LIST: add, remove or move food pictures.
const defaultFoodSprites = <FoodSprite>[
  FoodSprite(
    asset: 'assets/images/food_1.png',
    alignment: Alignment(-0.95, -0.8),
    size: 90,
    fromLeft: true,
    start: 0.0,
    end: 0.5,
    phase: 0.0,
  ),
  FoodSprite(
    asset: 'assets/images/food_2.png',
    alignment: Alignment(0.95, -0.55),
    size: 80,
    fromLeft: false,
    start: 0.1,
    end: 0.6,
    phase: 0.3,
  ),
  FoodSprite(
    asset: 'assets/images/food_3.png',
    alignment: Alignment(-0.95, 0.0),
    size: 85,
    fromLeft: true,
    start: 0.2,
    end: 0.7,
    phase: 0.6,
  ),
  FoodSprite(
    asset: 'assets/images/food_4.png',
    alignment: Alignment(0.95, 0.35),
    size: 90,
    fromLeft: false,
    start: 0.3,
    end: 0.8,
    phase: 0.15,
  ),
  FoodSprite(
    asset: 'assets/images/food_5.png',
    alignment: Alignment(-0.9, 0.85),
    size: 80,
    fromLeft: true,
    start: 0.4,
    end: 0.9,
    phase: 0.45,
  ),
  FoodSprite(
    asset: 'assets/images/food_6.png',
    alignment: Alignment(0.9, 0.9),
    size: 85,
    fromLeft: false,
    start: 0.5,
    end: 1.0,
    phase: 0.75,
  ),
];

/// Put this inside a Stack(fit: StackFit.expand).
/// [intro] plays once (slide in), [float] loops (gentle bobbing).
class SlidingFoodBackdrop extends StatelessWidget {
  const SlidingFoodBackdrop({
    super.key,
    required this.intro,
    required this.float,
    this.sprites = defaultFoodSprites,
  });

  final Animation<double> intro;
  final Animation<double> float;
  final List<FoodSprite> sprites;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final s in sprites)
          _SlidingSprite(sprite: s, intro: intro, float: float),
      ],
    );
  }
}

class _SlidingSprite extends StatelessWidget {
  const _SlidingSprite({
    required this.sprite,
    required this.intro,
    required this.float,
  });

  final FoodSprite sprite;
  final Animation<double> intro;
  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    final slide = CurvedAnimation(
      parent: intro,
      // easeOutBack = slides in, overshoots a little, settles. Try Curves.easeOutCubic for no bounce.
      curve: Interval(sprite.start, sprite.end, curve: Curves.easeOutBack),
    );
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([slide, float]),
      builder: (context, child) {
        // 1 -> 0 as it slides in
        final remaining = 1 - slide.value;
        final dx = remaining * (sprite.fromLeft ? -1 : 1) * screenWidth * 0.9;
        // gentle bobbing after it lands
        final t = (float.value + sprite.phase) % 1.0;
        final bob = math.sin(t * 2 * math.pi) * 6;
        return Align(
          alignment: sprite.alignment,
          child: Transform.translate(offset: Offset(dx, bob), child: child),
        );
      },
      child: Image.asset(
        sprite.asset,
        width: sprite.size,
        height: sprite.size,
        fit: BoxFit.contain,
        // placeholder shown only while the image file is missing
        errorBuilder: (_, __, ___) => SizedBox(
          width: sprite.size,
          height: sprite.size,
          child: Icon(
            Icons.image_outlined,
            size: sprite.size * 0.6,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}
