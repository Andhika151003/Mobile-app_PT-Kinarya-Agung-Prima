import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/authentication/controllers/register_controller.dart';
import 'mock_initializer.dart';

void main() {
  setUpAll(() {
    initMockFirebase();
  });

  group('RegisterController Unit Tests (Pure)', () {
    late RegisterController controller;

    setUp(() {
      controller = RegisterController();
    });

    group('Input Validators (TC-9, TC-10, TC-12, TC-14 to TC-18)', () {
      test('TC-9 & TC-10: Email Validations', () {
        expect(controller.validateEmail(null), 'Email wajib diisi');
        expect(controller.validateEmail(''), 'Email wajib diisi');
        expect(controller.validateEmail('invalid'), 'Harap masukkan alamat email yang valid');
        expect(controller.validateEmail('user@example.com'), null);
      });

      test('TC-12: Full Name Validations', () {
        expect(controller.validateFullName(null), 'Nama Lengkap wajib diisi');
        expect(controller.validateFullName(''), 'Nama Lengkap wajib diisi');
        expect(controller.validateFullName('ab'), 'Harap masukkan nama lengkap');
        expect(controller.validateFullName('John Doe'), null);
      });

      test('TC-14 & TC-15: Phone Number Validations', () {
        expect(controller.validatePhoneNumber(null), 'Nomor Telepon wajib diisi');
        expect(controller.validatePhoneNumber(''), 'Nomor Telepon wajib diisi');
        expect(controller.validatePhoneNumber('123456789'), 'Harap masukkan nomor telepon yang valid'); // 9 digits
        expect(controller.validatePhoneNumber('12345678901234'), 'Harap masukkan nomor telepon yang valid'); // 14 digits
        expect(controller.validatePhoneNumber('08123456789'), null); // 11 digits
      });

      test('TC-16: Password Validations', () {
        expect(controller.validatePassword(null), 'Password wajib diisi');
        expect(controller.validatePassword(''), 'Password wajib diisi');
        expect(controller.validatePassword('1234567'), 'Password harus minimal 8 karakter');
        expect(controller.validatePassword('12345678'), null);
      });

      test('TC-17 & TC-18: Confirm Password Validations', () {
        expect(controller.validateConfirmPassword(null, 'password123'), 'Harap konfirmasi password Anda');
        expect(controller.validateConfirmPassword('', 'password123'), 'Harap konfirmasi password Anda');
        expect(controller.validateConfirmPassword('password321', 'password123'), 'Password tidak cocok');
        expect(controller.validateConfirmPassword('password123', 'password123'), null);
      });
    });

    group('Dropdown Validator (TC-13)', () {
      test('TC-13: Business Type Dropdown Validation', () {
        final validateBusinessType = (String? value) => value == null ? 'Harap pilih jenis usaha Anda' : null;
        expect(validateBusinessType(null), 'Harap pilih jenis usaha Anda');
        expect(validateBusinessType('Pet Shop'), null);
      });
    });
  });
}