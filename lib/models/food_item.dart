class FoodItem {
  const FoodItem({
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
    this.tag,
  });

  final String name;
  final String description;
  final int price; // in pesos
  final String emoji; // swap for an image later
  final String category;
  final String? tag;
}
