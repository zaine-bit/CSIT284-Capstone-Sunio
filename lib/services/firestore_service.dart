import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/menu_data.dart';
import '../models/canteen_order.dart';
import '../models/food_item.dart';

/// All Firebase (Firestore) reads and writes live here.
///
/// Collections:
///   menu_items  -> the menu            (CRUD from the staff screen)
///   orders      -> student orders      (create / read / update status / delete)
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _menu =>
      _db.collection('menu_items');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  // ================= MENU (CRUD) =================

  /// READ: live list of menu items.
  Stream<List<FoodItem>> menuStream() => _menu
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(FoodItem.fromDoc).toList());

  /// CREATE
  Future<void> addMenuItem(FoodItem item) => _menu.add(item.toMap());

  /// UPDATE
  Future<void> updateMenuItem(FoodItem item) =>
      _menu.doc(item.id).update(item.toMap());

  /// DELETE
  Future<void> deleteMenuItem(String id) => _menu.doc(id).delete();

  /// Uploads the sample menu from data/menu_data.dart if Firestore has none.
  Future<void> seedMenuIfEmpty() async {
    final existing = await _menu.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final item in menuItems) {
      batch.set(_menu.doc(), item.toMap());
    }
    await batch.commit();
  }

  // ================= ORDERS (CRUD) =================

  /// CREATE: place a new order (starts as Pending).
  Future<String> placeOrder({
    required String studentId,
    required List<OrderLine> lines,
  }) async {
    final total = lines.fold<int>(0, (sum, l) => sum + l.price * l.qty);
    final ref = await _orders.add({
      'studentId': studentId,
      'items': lines.map((l) => l.toMap()).toList(),
      'total': total,
      'status': CanteenOrder.pending,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// READ: live orders of one student (newest first).
  Stream<List<CanteenOrder>> ordersForStudent(String studentId) => _orders
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((s) {
        final list = s.docs.map(CanteenOrder.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  /// READ: live list of ALL orders (for the canteen staff).
  Stream<List<CanteenOrder>> allOrders() => _orders.snapshots().map(
        (s) => s.docs.map(CanteenOrder.fromDoc).toList(),
      );

  /// UPDATE: change an order's status ('Pending' / 'Ready').
  Future<void> setOrderStatus(String id, String status) =>
      _orders.doc(id).update({'status': status});

  /// DELETE: cancel / remove an order.
  Future<void> deleteOrder(String id) => _orders.doc(id).delete();
}
