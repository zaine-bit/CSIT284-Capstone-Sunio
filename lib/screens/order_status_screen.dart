import 'package:flutter/material.dart';

import '../models/canteen_order.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';

const _readyGreen = Color(0xFF2E9E6B); // color of the "Ready" status

/// Live list of this student's orders. The status chip changes by itself
/// when the canteen staff marks an order as Ready.
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({
    super.key,
    required this.studentId,
    this.justPlaced = false,
  });

  final String studentId;
  final bool justPlaced; // show the "order placed" banner

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late final Stream<List<CanteenOrder>> _stream =
      FirestoreService.instance.ordersForStudent(widget.studentId);

  Future<void> _cancel(CanteenOrder order) async {
    final ok = await confirmDialog(
      context,
      title: 'Cancel order #${order.shortId}?',
      message: 'This removes your order from the canteen queue.',
      confirmLabel: 'Cancel order',
    );
    if (ok) await FirestoreService.instance.deleteOrder(order.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My orders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<CanteenOrder>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (widget.justPlaced) const _PlacedBanner(),
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'No orders yet.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              for (final order in orders)
                _OrderCard(order: order, onCancel: () => _cancel(order)),
            ],
          );
        },
      ),
    );
  }
}

class _PlacedBanner extends StatelessWidget {
  const _PlacedBanner();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value.clamp(0.0, 1.2),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.accent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Order placed! We will mark it Ready when it is done. '
                'Pay with cash at pickup.',
                style: TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onCancel});

  final CanteenOrder order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.shortId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            order.timeLabel,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${line.qty}x ${line.name}')),
                  Text('₱${line.price * line.qty}'),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '₱${order.total}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (order.isReady) ...[
            const SizedBox(height: 12),
            const Text(
              'Ready! Pick it up at the counter and pay with cash.',
              style: TextStyle(
                color: _readyGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!order.isReady) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel order'),
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pending (yellow) / Ready (green). Animates when the status changes.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ready = status == CanteenOrder.ready;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ready ? _readyGreen : AppColors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ready ? Icons.check_rounded : Icons.hourglass_top_rounded,
              size: 16,
              color: ready ? Colors.white : AppColors.text,
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ready ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
