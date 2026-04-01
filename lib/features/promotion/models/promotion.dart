import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionModel {
  final String? id;
  final String title;
  final String description;
  final String discountType;
  final double discountValue;
  final List<String> productIds;
  final String applicableTo;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final String status;
  final String? imageUrl;
  final String sku;
  final DateTime createdAt;
  final String createdBy;

  PromotionModel({
    this.id,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.productIds,
    required this.applicableTo,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.imageUrl,
    required this.sku,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'productIds': productIds,
      'applicableTo': applicableTo,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'imageUrl': imageUrl,
      'sku': sku,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  factory PromotionModel.fromMap(String id, Map<String, dynamic> map) {
    return PromotionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountType: map['discountType'] ?? 'percentage',
      discountValue: (map['discountValue'] ?? 0).toDouble(),
      productIds: List<String>.from(map['productIds'] ?? []),
      applicableTo: map['applicableTo'] ?? 'all',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '23:59',
      status: map['status'] ?? 'active',
      imageUrl: map['imageUrl'],
      sku: map['sku'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return status == 'active' && now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isEndingSoon {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return isActive && endDate.isBefore(threeDaysFromNow);
  }

  String get discountText {
    switch (discountType) {
      case 'percentage':
        return '${discountValue.toInt()}% OFF';
      case 'fixed':
        return 'Rp ${discountValue.toStringAsFixed(0)} OFF';
      case 'bogo':
        return 'BOGO';
      case 'bundle':
        return 'Bundle Deal';
      default:
        return 'Diskon';
    }
  }

  String get formattedDateRange {
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonth(date.month)} ${date.year}';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}