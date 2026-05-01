class CartItem {
  final String id;
  final String title;
  final String variant;
  final double price;
  final String imageUrl;
  final String category; 
  int quantity;
  int minOrder; 
  int stockLimit; 

  CartItem({
    required this.id,
    required this.title,
    required this.variant,
    required this.price,
    required this.imageUrl,
    required this.category,
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
      'category': category,
      'quantity': quantity,
      'minOrder': minOrder,
      'stockLimit': stockLimit,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      title: map['title'] as String,
      variant: map['variant'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      category: map['category'] as String? ?? 'Uncategorized',
      quantity: (map['quantity'] as num).toInt(),
      minOrder: (map['minOrder'] as num).toInt(),
      stockLimit: (map['stockLimit'] as num).toInt(),
    );
  }
}