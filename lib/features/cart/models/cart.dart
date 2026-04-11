class CartItem {
  final String id;
  final String title;
  final String variant;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.variant,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'variant': variant,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }
}