import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String? productId; 
  final String title;
  final String variant;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItemModel({
    this.productId,
    required this.title,
    required this.variant,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId']?.toString() ?? map['id']?.toString(),
      title: map['title']?.toString() ?? 'Unknown Item',
      variant: map['variant']?.toString() ?? '-',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (productId != null) 'productId': productId,
      'title': title,
      'variant': variant,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}

class OrderModel {
  final String orderId;
  final String userId;
  final String fullName;
  final String shippingAddress;
  
  final String paymentMethod;
  final String? paymentMethodCode;
  final String promoCode;
  
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double total;
  
  final List<OrderItemModel> items;
  final String status; 
  final String? paymentUrl;
  
  final DateTime? createdAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.fullName,
    required this.shippingAddress,
    required this.paymentMethod,
    this.paymentMethodCode,
    required this.promoCode,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    required this.total,
    required this.items,
    required this.status,
    this.paymentUrl,
    this.createdAt,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic dateData) {
      if (dateData is Timestamp) return dateData.toDate().toLocal();
      if (dateData is String) return DateTime.tryParse(dateData)?.toLocal();
      return null;
    }

    var itemList = map['items'] as List? ?? [];
    List<OrderItemModel> parsedItems = itemList
        .map((item) => OrderItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    String rawStatus = map['status']?.toString() ?? 'Ordered';
    if (rawStatus == 'Pending Payment') rawStatus = 'Ordered';
    if (rawStatus == 'Settled') rawStatus = 'Delivered';

    return OrderModel(
      orderId: map['orderId']?.toString() ?? '-',
      userId: map['userId']?.toString() ?? '-',
      fullName: map['fullName']?.toString() ?? 'Customer',
      shippingAddress: map['shippingAddress']?.toString() ?? 'Alamat tidak tersedia',
      
      paymentMethod: map['paymentMethod']?.toString() ?? '-',
      paymentMethodCode: map['paymentMethodCode']?.toString(),
      promoCode: map['promoCode']?.toString() ?? '-',
      
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingCost: (map['shippingCost'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      
      items: parsedItems,
      status: rawStatus,
      paymentUrl: map['paymentUrl']?.toString(),
      
      createdAt: parseDate(map['createdAt']),
      paidAt: parseDate(map['paidAt']),
      shippedAt: parseDate(map['shippedAt']),
      deliveredAt: parseDate(map['deliveredAt']) ?? parseDate(map['settledAt']), 
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'fullName': fullName,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      if (paymentMethodCode != null) 'paymentMethodCode': paymentMethodCode,
      'promoCode': promoCode,
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'tax': tax,
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status,
      'paymentUrl': paymentUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  OrderModel copyWith({
    String? status,
    DateTime? paidAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      orderId: orderId,
      userId: userId,
      fullName: fullName,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      paymentMethodCode: paymentMethodCode,
      promoCode: promoCode,
      subtotal: subtotal,
      shippingCost: shippingCost,
      tax: tax,
      total: total,
      items: items,
      status: status ?? this.status,
      paymentUrl: paymentUrl ?? paymentUrl,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}