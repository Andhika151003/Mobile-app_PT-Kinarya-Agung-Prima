import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/features/complaint/models/complaint.dart';

void main() {
  group('ComplaintModel Unit Tests', () {
    final DateTime mockTime = DateTime(2026, 1, 1);
    final Timestamp mockTimestamp = Timestamp.fromDate(mockTime);

    final Map<String, dynamic> completeMockMap = {
      'userId': 'user123',
      'imgUrl': 'http://image.url',
      'orderId': 'order123',
      'productName': 'Product A',
      'issueType': 'Damaged Item',
      'description': 'The item arrived broken',
      'imageUrls': ['http://image1.url', 'http://image2.url'],
      'status': 'resolved',
      'createdAt': mockTimestamp,
      'resolvedAt': mockTimestamp,
      'resolvedBy': 'admin1',
      'resolvedByName': 'Admin One',
    };

    test('fromMap() harus parsing Map lengkap dari Firestore menjadi objek ComplaintModel dengan benar', () {
      final model = ComplaintModel.fromMap('complaint_doc_id', completeMockMap);

      expect(model.id, 'complaint_doc_id');
      expect(model.userId, 'user123');
      expect(model.imgUrl, 'http://image.url');
      expect(model.orderId, 'order123');
      expect(model.productName, 'Product A');
      expect(model.issueType, 'Damaged Item');
      expect(model.description, 'The item arrived broken');
      expect(model.imageUrls, ['http://image1.url', 'http://image2.url']);
      expect(model.status, 'resolved');
      expect(model.createdAt, mockTime);
      expect(model.resolvedAt, mockTime);
      expect(model.resolvedBy, 'admin1');
      expect(model.resolvedByName, 'Admin One');
    });

    test('fromMap() harus menangani field null dengan nilai default yang aman', () {
      final Map<String, dynamic> incompleteMockMap = {
        'createdAt': mockTimestamp, // createdAt wajib ada karena dia nge-cast langsung
      };

      final model = ComplaintModel.fromMap('complaint_doc_id', incompleteMockMap);

      expect(model.id, 'complaint_doc_id');
      expect(model.userId, '');
      expect(model.imgUrl, '');
      expect(model.orderId, '');
      expect(model.productName, null);
      expect(model.issueType, '');
      expect(model.description, '');
      expect(model.imageUrls, []);
      expect(model.status, 'pending');
      expect(model.createdAt, mockTime);
      expect(model.resolvedAt, null);
      expect(model.resolvedBy, null);
      expect(model.resolvedByName, null);
    });

    test('toMap() harus mengonversi model menjadi Map Firebase dengan benar', () {
      final model = ComplaintModel(
        id: 'complaint_doc_id',
        userId: 'user123',
        imgUrl: 'http://image.url',
        orderId: 'order123',
        productName: 'Product A',
        issueType: 'Damaged Item',
        description: 'The item arrived broken',
        imageUrls: ['http://image1.url'],
        status: 'pending',
        createdAt: mockTime,
        resolvedAt: mockTime,
        resolvedBy: 'admin1',
        resolvedByName: 'Admin One',
      );

      final map = model.toMap();

      expect(map['userId'], 'user123');
      expect(map['imgUrl'], 'http://image.url');
      expect(map['orderId'], 'order123');
      expect(map['productName'], 'Product A');
      expect(map['issueType'], 'Damaged Item');
      expect(map['description'], 'The item arrived broken');
      expect(map['imageUrls'], ['http://image1.url']);
      expect(map['status'], 'pending');
      expect((map['createdAt'] as Timestamp).toDate(), mockTime);
      expect((map['resolvedAt'] as Timestamp).toDate(), mockTime);
      expect(map['resolvedBy'], 'admin1');
      expect(map['resolvedByName'], 'Admin One');
    });
  });
}
