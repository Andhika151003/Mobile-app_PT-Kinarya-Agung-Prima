import '../models/address_model.dart';
import '../services/address_service.dart';
import '../../../core/utils/result.dart';

class AddressController {
  final AddressService _addressService;

  AddressController({AddressService? addressService})
      : _addressService = addressService ?? AddressService();

  Stream<List<AddressModel>> getAddresses() {
    return _addressService.getAddresses();
  }

  Future<Result<void>> addAddress(AddressModel address) async {
    return await _addressService.addAddress(address);
  }

  Future<Result<void>> updateAddress(AddressModel address) async {
    return await _addressService.updateAddress(address);
  }

  Future<Result<void>> deleteAddress(String id) async {
    return await _addressService.deleteAddress(id);
  }

  Future<Result<void>> setDefaultAddress(String id) async {
    return await _addressService.setDefaultAddress(id);
  }

  Future<Result<AddressModel?>> getDefaultAddress() async {
    return await _addressService.getDefaultAddress();
  }
}
