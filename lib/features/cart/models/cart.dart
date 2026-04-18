class CartItem {
  final String id;
  final String title;
  final String variant;
  final double price;
  final String imageUrl;
  int quantity;
  int minOrder; 
  int stockLimit; 

  CartItem({
    required this.id,
    required this.title,
    required this.variant,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    required this.minOrder,   
    required this.stockLimit, 
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'variant': variant,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'minOrder': minOrder,
      'stockLimit': stockLimit,
    };
  }
}