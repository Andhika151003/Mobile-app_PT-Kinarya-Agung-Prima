import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/admin/controller/admin_master_controller.dart';
import '../authentication/mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('AdminMasterController Unit Tests (Pure)', () {
    setUp(() {
      // Just instantiate to ensure no compile or setup errors
      AdminMasterController();
    });

    group('Retailer ID Formatting Logic', () {
      String formatRetailerId(String uid) {
        return '#KNY${uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase()}';
      }

      test('Format short UID (< 6 chars)', () {
        expect(formatRetailerId('abc'), '#KNYABC');
        expect(formatRetailerId('12345'), '#KNY12345');
      });

      test('Format long UID (>= 6 chars)', () {
        expect(formatRetailerId('retailer_john'), '#KNYRETAIL');
        expect(formatRetailerId('ret_123456'), '#KNYRET_12');
      });
    });

    group('Search & Filter Logic (Pure Validation)', () {
      final List<Map<String, dynamic>> mockRetailers = [
        {'id': 'retailer_john', 'fullName': 'John Doe Store', 'email': 'john@doe.com', 'isActive': true},
        {'id': 'retailer_mary', 'fullName': 'Mary Jane Shop', 'email': 'mj@example.com', 'isActive': true},
        {'id': 'ret_inactive', 'fullName': 'Inactive Store', 'email': 'inactive@shop.com', 'isActive': false},
      ];

      List<Map<String, dynamic>> searchRetailers(List<Map<String, dynamic>> list, String query) {
        if (query.isEmpty) return list;
        return list.where((retailer) {
          final fullName = retailer['fullName']?.toLowerCase() ?? '';
          final email = retailer['email']?.toLowerCase() ?? '';
          
          final uid = retailer['id'] ?? '';
          final formattedId = '#KNY${uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase()}';
          
          final search = query.toLowerCase();
          return fullName.contains(search) || 
                 email.contains(search) || 
                 formattedId.toLowerCase().contains(search);
        }).toList();
      }

      test('Search by exact name (case-insensitive)', () {
        final result = searchRetailers(mockRetailers, 'JOHN');
        expect(result.length, 1);
        expect(result.first['id'], 'retailer_john');
      });

      test('Search by partial name', () {
        final result = searchRetailers(mockRetailers, 'Jane');
        expect(result.length, 1);
        expect(result.first['id'], 'retailer_mary');
      });

      test('Search by email', () {
        final result = searchRetailers(mockRetailers, 'doe.com');
        expect(result.length, 1);
        expect(result.first['id'], 'retailer_john');
      });

      test('Search by formatted ID', () {
        // UID: retailer_john -> #KNYRETAIL
        final result = searchRetailers(mockRetailers, '#KNYRETAIL');
        expect(result.length, 2); // both starts with 'retail' (retailer_john, retailer_mary)
      });

      test('Search query empty resets list', () {
        final result = searchRetailers(mockRetailers, '');
        expect(result.length, 3);
      });
    });
  });
}
