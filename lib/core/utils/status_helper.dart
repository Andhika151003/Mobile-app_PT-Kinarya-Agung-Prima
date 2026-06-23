extension OrderStatusExtension on String {
  /// Converts English DB statuses to Indonesian display statuses.
  String get displayStatus {
    switch (this) {
      case 'Ordered':
      case 'Pending Payment':
        return 'Belum bayar';
      case 'Paid':
        return 'Dikemas';
      case 'Shipped':
        return 'Dikirim';
      case 'Delivered':
        return 'Selesai';
      case 'Cancelled':
        return 'Dibatalkan';
      case 'Expired':
        return 'Kedaluwarsa';
      default:
        return this;
    }
  }
}
