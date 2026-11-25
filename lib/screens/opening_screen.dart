import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/food_slide_in.dart';
import '../widgets/reveal.dart';
import 'menu_screen.dart';
import 'staff_screen.dart';
import 'package:google_fonts/google_fonts.dart';

/// First screen: enter student ID, then go to the menu.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with TickerProviderStateMixin {
  // plays once when the screen opens
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  // loops forever (floating food emojis)
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  final _idController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _continue() {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Enter your student ID to continue');
      return;
    }
    setState(() => _error = null);
    FocusScope.of(context).unfocus();

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => MenuScreen(studentId: id),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 250, 183),
      body: Column(
        children: [
          Expanded(child: _buildHero()),
          _buildFormPanel(),
        ],
      ),
    );
  }

  // ----- top half: logo, name, floating emojis -----
  Widget _buildHero() {
    final logoScale = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );

    return SafeArea(
      bottom: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // food pictures that slide in from the sides (edit in widgets/food_slide_in.dart)
          SlidingFoodBackdrop(intro: _intro, float: _float),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo: bounces in once, then floats gently.
                // Change 'assets/images/logo.png' to your file name.
                ScaleTransition(
                  scale: logoScale,
                  child: AnimatedBuilder(
                    animation: _float,
                    builder: (context, child) {
                      final dy = math.sin(_float.value * 2 * math.pi) * 8;
                      return Transform.translate(
                          offset: Offset(0, dy), child: child);
                    },
                    child: Image.asset(
                      'assets/images/open_logo-removebg-preview.png',
                      width: 400,
                      height: 400,
                      fit: BoxFit.contain,
                      // placeholder shown only while the image file is missing
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 140,
                        height: 140,
                        child: Icon(
                          Icons.image_outlined,
                          size: 200,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Reveal(
                  controller: _intro,
                  start: 0.3,
                  end: 0.7,
                  child: Text(
                    'BiteHub',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lilitaOne(
                      fontSize: 50,
                      height: 1.1,
                      color: const Color.fromARGB(255, 163, 63, 63),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Reveal(
                  controller: _intro,
                  start: 0.4,
                  end: 0.8,
                  child: Text(
                    'Order ahead before the bell rings!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(204, 56, 34, 5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- bottom half: student ID form -----
  Widget _buildFormPanel() {
    return Reveal(
      controller: _intro,
      start: 0.5,
      end: 1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your student ID',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'No account needed. We use it to name your order.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _idController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: 'e.g. 24-8464-987',
                  filled: true,
                  fillColor: AppColors.card,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              // error text slides open / closed
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.topLeft,
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text("See today's menu"),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Pay with cash when you pick up',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => openStaffGate(context),
                  child: const Text('Canteen staff'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
