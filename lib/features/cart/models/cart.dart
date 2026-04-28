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

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      title: map['title'] as String,
      variant: map['variant'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      quantity: (map['quantity'] as num).toInt(),
      minOrder: (map['minOrder'] as num).toInt(),
      stockLimit: (map['stockLimit'] as num).toInt(),
    );
  }
}