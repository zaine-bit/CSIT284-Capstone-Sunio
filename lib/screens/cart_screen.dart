import 'package:flutter/material.dart';

import '../models/canteen_order.dart';
import '../models/food_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/food_image.dart';
import 'order_status_screen.dart';

/// Shows what's in the cart, lets the student change quantities,
/// and places the order (saved to Firestore as 'Pending').
class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.studentId,
    required this.menu,
    required this.cart,
    required this.onChanged,
  });

  final String studentId;
  final List<FoodItem> menu;
  final Map<String, int> cart; // item id -> quantity (shared with MenuScreen)
  final VoidCallback onChanged;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;

  List<MapEntry<FoodItem, int>> get _lines => [
        for (final item in widget.menu)
          if ((widget.cart[item.id] ?? 0) > 0)
            MapEntry(item, widget.cart[item.id]!),
      ];

  int get _total => _lines.fold<int>(0, (s, e) => s + e.key.price * e.value);

  void _change(FoodItem item, int delta) {
    setState(() {
      final qty = (widget.cart[item.id] ?? 0) + delta;
      if (qty <= 0) {
        widget.cart.remove(item.id);
      } else {
        widget.cart[item.id] = qty;
      }
    });
    widget.onChanged();
  }

  Future<void> _placeOrder() async {
    final lines = _lines;
    if (lines.isEmpty || _placing) return;
    setState(() => _placing = true);

    try {
      await FirestoreService.instance.placeOrder(
        studentId: widget.studentId,
        lines: [
          for (final e in lines)
            OrderLine(name: e.key.name, price: e.key.price, qty: e.value),
        ],
      );
      if (!mounted) return;
      // result: true tells MenuScreen to clear its cart
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(
            studentId: widget.studentId,
            justPlaced: true,
          ),
        ),
        result: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your cart',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: lines.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: lines.length,
                    itemBuilder: (context, i) {
                      final item = lines[i].key;
                      final qty = lines[i].value;
                      return _CartLine(
                        item: item,
                        qty: qty,
                        onAdd: () => _change(item, 1),
                        onRemove: () => _change(item, -1),
                      );
                    },
                  ),
                ),
                _buildCheckoutBar(),
              ],
            ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '₱$_total',
                    key: ValueKey(_total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pay with cash when you pick up',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _placing ? null : _placeOrder,
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
                child: _placing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Text('Place order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final FoodItem item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          FoodImage(image: item.image, size: 56, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '₱${item.price} each',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$qty',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
