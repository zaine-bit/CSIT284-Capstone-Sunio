import 'package:cloud_firestore/cloud_firestore.dart';

/// One line inside an order (e.g. 2x Iced Tea).
class OrderLine {
  const OrderLine({
    required this.name,
    required this.price,
    required this.qty,
  });

  final String name;
  final int price; // price of ONE item
  final int qty;

  Map<String, dynamic> toMap() => {'name': name, 'price': price, 'qty': qty};

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        name: m['name'] as String? ?? '',
        price: (m['price'] as num?)?.toInt() ?? 0,
        qty: (m['qty'] as num?)?.toInt() ?? 1,
      );
}

class CanteenOrder {
  const CanteenOrder({
    required this.id,
    required this.studentId,
    required this.lines,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  static const pending = 'Pending';
  static const ready = 'Ready';

  final String id;
  final String studentId;
  final List<OrderLine> lines;
  final int total;
  final String status; // 'Pending' or 'Ready'
  final DateTime createdAt;

  bool get isReady => status == ready;

  /// Short order number shown to the user, e.g. A3F9
  String get shortId =>
      id.length >= 4 ? id.substring(id.length - 4).toUpperCase() : id;

  String get timeLabel {
    final h = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final m = createdAt.minute.toString().padLeft(2, '0');
    final ap = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  factory CanteenOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final rawLines = (d['items'] as List<dynamic>? ?? []);
    final ts = d['createdAt'];
    return CanteenOrder(
      id: doc.id,
      studentId: d['studentId'] as String? ?? '',
      lines: [
        for (final l in rawLines)
          OrderLine.fromMap(Map<String, dynamic>.from(l as Map)),
      ],
      total: (d['total'] as num?)?.toInt() ?? 0,
      status: d['status'] as String? ?? pending,
      // createdAt is briefly null while the server timestamp is being set
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
