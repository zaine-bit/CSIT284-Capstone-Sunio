import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

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
    this.peek = 0.4,
    this.peekY = 0,
    this.tilt = 0,
    this.shadowX = 0.05,
    this.shadowY = 0.07,
  });

  final String asset; // e.g. 'assets/images/food_1.png'
  final Alignment alignment; // where it ends up: (-1,-1) top-left ... (1,1) bottom-right
  final double size; // width/height in px
  final bool fromLeft; // true = enters from the left edge, false = from the right
  final double start; // when it starts sliding (0.0 - 1.0 of the intro animation)
  final double end; // when it lands (0.0 - 1.0)
  final double phase; // offsets the gentle up/down bobbing (0.0 - 1.0)
  final double peek; // how much hides off the left/right edge (0.0 - 1.0)
  final double peekY; // how much hides off the bottom/top edge (0.0 - 1.0)
  final double tilt; // rotation in radians (0.3 is about 17 degrees)
  final double shadowX; // shadow right (+) or left (-), as a fraction of size
  final double shadowY; // shadow down (+) or up (-), as a fraction of size
}


/// EDIT THIS LIST: add, remove or move food pictures.
const defaultFoodSprites = <FoodSprite>[
  FoodSprite(
    asset: 'assets/images/chickenadoborice.png',
    alignment: Alignment(-0.95, -2.0),
    size: 400,
    fromLeft: true,
    start: 0.0,
    end: 0.5,
    phase: 0.0,
    peek: 0.45, // 45% hidden off-screen
    tilt: 0.35,
  ),
  FoodSprite(
    asset: 'assets/images/porksisigrice.png',
    alignment: Alignment(0.95, -2.0),
    size: 400,
    fromLeft: false,
    start: 0.1,
    end: 0.6,
    phase: 0.3,
    peek: 0.45,
    tilt: -0.35,
  ),
  
  FoodSprite(
    asset: 'assets/images/tapsilog.png',
    alignment: Alignment(-0.9, 0.5),
    size: 400,
    fromLeft: true,
    start: 0.4,
    end: 0.9,
    phase: 0.45,
    peekY: 0.4, // also hides behind the white panel
    tilt: 0.4,
    shadowX: 0.06, // shadow falls to the LEFT
    shadowY: -0.03,  // and a little down
  ),
  FoodSprite(
    asset: 'assets/images/pancitcanton.png',
    alignment: Alignment(0.9, 2.0),
    size: 400,
    fromLeft: false,
    start: 0.5,
    end: 1.0,
    phase: 0.75,
    peek: 0.4,
    tilt: -0.35,
    shadowX: -0.06, // shadow falls to the LEFT
    shadowY: -0.03,  // and a little down
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

  // ---- shadow settings: edit these ----
    static const _shadowColor = Color(0x66000000); // 66 = 40% black. Try 0x99 for darker // AA = about 67% black // 66 = 40% black. Try 0x99 for darker
   // right, down

  @override
  Widget build(BuildContext context) {
    final slide = CurvedAnimation(
      parent: intro,
      curve: Interval(sprite.start, sprite.end, curve: Curves.easeOutBack),
    );
    final screenWidth = MediaQuery.of(context).size.width;
        // direction stays the same on screen even if the image is tilted
    final sx = sprite.size * sprite.shadowX;
    final sy = sprite.size * sprite.shadowY;
    final c = math.cos(sprite.tilt);
    final s = math.sin(sprite.tilt);
    final shadowOffset = Offset(sx * c + sy * s, -sx * s + sy * c);
    final shadowBlur = sprite.size * 0.04;

    return AnimatedBuilder(
      animation: Listenable.merge([slide, float]),
      builder: (context, child) {
        // 1 -> 0 as it slides in
        final remaining = 1 - slide.value;
        final dx = remaining * (sprite.fromLeft ? -1 : 1) * screenWidth * 0.9;
        // the part hidden off the screen edge (the "peek")
        final hideX = (sprite.fromLeft ? -1 : 1) * sprite.size * sprite.peek;
        final hideY = sprite.alignment.y.sign * sprite.size * sprite.peekY;
        // gentle bobbing after it lands
        final t = (float.value + sprite.phase) % 1.0;
        final bob = math.sin(t * 2 * math.pi) * 6;
        return Align(
          alignment: sprite.alignment,
          child: Transform.translate(
            offset: Offset(dx + hideX, bob + hideY),
            child: Transform.rotate(angle: sprite.tilt, child: child),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // shadow: a blurred dark copy of the same picture
          Transform.translate(
           offset: shadowOffset,
            child: ImageFiltered(
                            imageFilter:
                  ImageFilter.blur(sigmaX: shadowBlur, sigmaY: shadowBlur),
              child: ColorFiltered(
                colorFilter:
                    const ColorFilter.mode(_shadowColor, BlendMode.srcIn),
                child: Image.asset(
                  sprite.asset,
                  width: sprite.size,
                  height: sprite.size,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          // the real picture on top
          Image.asset(
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
        ],
      ),
    );
  }
}
