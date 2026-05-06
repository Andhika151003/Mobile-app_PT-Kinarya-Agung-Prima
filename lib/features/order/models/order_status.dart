enum OrderStatus {
  ordered,
  paid,
  shipped,
  delivered,
  cancelled,
  expired;

  String get value {
    switch (this) {
      case OrderStatus.ordered: return 'Ordered';
      case OrderStatus.paid: return 'Paid';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
      case OrderStatus.expired: return 'Expired';
    }
  }

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => OrderStatus.ordered,
    );
  }
}
