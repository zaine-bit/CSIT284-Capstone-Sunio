import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  const FoodItem({
    this.id = '',
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    this.tag,
  });

  final String id; // Firestore document id ('' if not saved yet)
  final String name;
  final String description;
  final int price; // in pesos
  final String image; // asset path, e.g. assets/images/menu_iced_tea.png
  final String category;
  final String? tag;

  factory FoodItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final tag = d['tag'] as String?;
    return FoodItem(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      price: (d['price'] as num?)?.toInt() ?? 0,
      image: d['image'] as String? ?? '',
      category: d['category'] as String? ?? 'Meals',
      tag: (tag == null || tag.isEmpty) ? null : tag,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'image': image,
        'category': category,
        'tag': tag,
      };
}
