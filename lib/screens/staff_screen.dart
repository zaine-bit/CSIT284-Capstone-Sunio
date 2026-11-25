import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../models/canteen_order.dart';
import '../models/food_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/food_image.dart';
import 'order_status_screen.dart' show StatusChip;

const staffPin = '1234'; // change this. (Simple gate for the capstone, not real security.)

/// Asks for the staff PIN, then opens the staff screen.
Future<void> openStaffGate(BuildContext context) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Staff PIN'),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'Enter PIN'),
        onSubmitted: (_) => Navigator.pop(ctx, controller.text == staffPin),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx), // null = cancelled
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text == staffPin),
          child: const Text('Enter'),
        ),
      ],
    ),
  );

  if (!context.mounted) return;
  if (ok == true) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StaffScreen()),
    );
  } else if (ok == false) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wrong PIN')),
    );
  }
}

/// Canteen side: manage orders (update status / delete) and the menu (CRUD).
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Canteen staff',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Menu'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StaffOrdersTab(),
            _StaffMenuTab(),
          ],
        ),
      ),
    );
  }
}

// ======================= ORDERS TAB =======================

class _StaffOrdersTab extends StatefulWidget {
  const _StaffOrdersTab();

  @override
  State<_StaffOrdersTab> createState() => _StaffOrdersTabState();
}

class _StaffOrdersTabState extends State<_StaffOrdersTab> {
  late final Stream<List<CanteenOrder>> _stream =
      FirestoreService.instance.allOrders();

  Future<void> _delete(CanteenOrder order) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete order #${order.shortId}?',
      message: 'This permanently removes the order.',
      confirmLabel: 'Delete',
    );
    if (ok) await FirestoreService.instance.deleteOrder(order.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CanteenOrder>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Pending first (oldest first), then Ready (newest first)
        final orders = [...snapshot.data!]..sort((a, b) {
            if (a.isReady != b.isReady) return a.isReady ? 1 : -1;
            return a.isReady
                ? b.createdAt.compareTo(a.createdAt)
                : a.createdAt.compareTo(b.createdAt);
          });
        final pendingCount = orders.where((o) => !o.isReady).length;

        if (orders.isEmpty) {
          return const Center(
            child: Text(
              'No orders yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$pendingCount pending',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            for (final order in orders)
              _StaffOrderCard(
                order: order,
                onToggle: () => FirestoreService.instance.setOrderStatus(
                  order.id,
                  order.isReady ? CanteenOrder.pending : CanteenOrder.ready,
                ),
                onDelete: () => _delete(order),
              ),
          ],
        );
      },
    );
  }
}

class _StaffOrderCard extends StatelessWidget {
  const _StaffOrderCard({
    required this.order,
    required this.onToggle,
    required this.onDelete,
  });

  final CanteenOrder order;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

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
                  '#${order.shortId}  ·  Student ${order.studentId}',
                  style: const TextStyle(
                    fontSize: 16,
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
          const SizedBox(height: 10),
          for (final line in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${line.qty}x ${line.name}'),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '₱${order.total}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (order.isReady)
                OutlinedButton(
                  onPressed: onToggle,
                  child: const Text('Back to Pending'),
                )
              else
                FilledButton.icon(
                  onPressed: onToggle,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark Ready'),
                ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete order',
                icon: const Icon(Icons.delete_outline, color: AppColors.coral),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================= MENU TAB =======================

class _StaffMenuTab extends StatefulWidget {
  const _StaffMenuTab();

  @override
  State<_StaffMenuTab> createState() => _StaffMenuTabState();
}

class _StaffMenuTabState extends State<_StaffMenuTab> {
  late final Stream<List<FoodItem>> _stream =
      FirestoreService.instance.menuStream();

  Future<void> _delete(FoodItem item) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete "${item.name}"?',
      message: 'It will disappear from the menu.',
      confirmLabel: 'Delete',
    );
    if (ok) await FirestoreService.instance.deleteMenuItem(item.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FoodItem>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showMenuItemDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add menu item'),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: Text(
                    'No menu items yet.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            for (final item in items)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: FoodImage(image: item.image, size: 48, radius: 12),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${item.category}  ·  ₱${item.price}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => showMenuItemDialog(context, item: item),
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _delete(item),
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Add (item == null) or edit (item given) a menu item.
Future<void> showMenuItemDialog(BuildContext context, {FoodItem? item}) async {
  final name = TextEditingController(text: item?.name ?? '');
  final desc = TextEditingController(text: item?.description ?? '');
  final price = TextEditingController(text: item?.price.toString() ?? '');
  final image = TextEditingController(text: item?.image ?? '');
  final tag = TextEditingController(text: item?.tag ?? '');
  var category = item?.category ?? 'Meals';
  String? error;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(item == null ? 'Add menu item' : 'Edit menu item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₱)'),
              ),
              TextField(
                controller: image,
                decoration: const InputDecoration(
                  labelText: 'Image path (assets/images/...png)',
                ),
              ),
              TextField(
                controller: tag,
                decoration: const InputDecoration(
                  labelText: 'Tag (optional, e.g. New)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: category,
                items: [
                  for (final c in categories.where((c) => c != 'All'))
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setLocal(() => category = v ?? category),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: const TextStyle(color: AppColors.coral),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final p = int.tryParse(price.text.trim());
              if (name.text.trim().isEmpty || p == null || p <= 0) {
                setLocal(() => error = 'Enter a name and a price above 0');
                return;
              }
              final saved = FoodItem(
                id: item?.id ?? '',
                name: name.text.trim(),
                description: desc.text.trim(),
                price: p,
                image: image.text.trim(),
                category: category,
                tag: tag.text.trim().isEmpty ? null : tag.text.trim(),
              );
              if (item == null) {
                await FirestoreService.instance.addMenuItem(saved);
              } else {
                await FirestoreService.instance.updateMenuItem(saved);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
