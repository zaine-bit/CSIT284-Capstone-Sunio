import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/food_item.dart';
import '../theme/app_colors.dart';
import '../widgets/food_card.dart';

/// Category chips, animated list, add/remove, floating cart bar.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _category = 'All';
  final Map<String, int> _cart = {}; // item name -> quantity

  int get _count => _cart.values.fold<int>(0, (a, b) => a + b);

  int get _total => menuItems.fold<int>(
      0, (sum, item) => sum + item.price * (_cart[item.name] ?? 0));

  List<FoodItem> get _visibleItems => _category == 'All'
      ? menuItems
      : menuItems.where((i) => i.category == _category).toList();

  void _add(FoodItem item) =>
      setState(() => _cart[item.name] = (_cart[item.name] ?? 0) + 1);

  void _remove(FoodItem item) {
    setState(() {
      final qty = (_cart[item.name] ?? 0) - 1;
      if (qty <= 0) {
        _cart.remove(item.name);
      } else {
        _cart[item.name] = qty;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildPickupBanner(),
                const SizedBox(height: 16),
                _buildCategoryChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: ListView.builder(
                      // new key = list re-animates when category changes
                      key: ValueKey(_category),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(
                              milliseconds: 350 + math.min(index, 6) * 70),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: FoodCard(
                            item: item,
                            qty: _cart[item.name] ?? 0,
                            onAdd: () => _add(item),
                            onRemove: () => _remove(item),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            _buildCartBar(),
          ],
        ),
      ),
    );
  }

  // ----- greeting + back button -----
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student ${widget.studentId}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'What are you\neating today?',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Change student ID',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }

  // ----- "cash on pickup" reminder -----
  Widget _buildPickupBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.payments_outlined, color: AppColors.accent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pick up at the counter and pay with cash.',
              style: TextStyle(color: AppColors.onPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ----- category chips -----
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final name = categories[index];
          final selected = name == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(22),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.onPrimary : AppColors.text,
                ),
                child: Text(name),
              ),
            ),
          );
        },
      ),
    );
  }

  // ----- floating cart bar (slides up when cart has items) -----
  Widget _buildCartBar() {
    final hasItems = _count > 0;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: IgnorePointer(
        ignoring: !hasItems,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          offset: hasItems ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: hasItems ? 1 : 0,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  // TODO: open cart screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cart screen comes next')),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Text(
                            '$_count',
                            key: ValueKey(_count),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'View cart',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '₱$_total',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
