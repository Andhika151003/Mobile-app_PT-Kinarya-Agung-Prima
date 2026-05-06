import '../../../core/error/failures.dart';
import '../../../core/repositories/address_repository.dart';
import '../../../core/utils/result.dart';
import '../models/address_model.dart';

class AddressService {
  final AddressRepository _addressRepository;

  AddressService({AddressRepository? addressRepository})
      : _addressRepository = addressRepository ?? AddressRepository();

  Stream<List<AddressModel>> getAddresses() {
    return _addressRepository.getAddressesStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AddressModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<Result<void>> addAddress(AddressModel address) async {
    try {
      if (address.isDefault) {
        await _clearDefault();
      }
      await _addressRepository.addAddress(address.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal menambahkan alamat: $e'));
    }
  }

  Future<Result<void>> updateAddress(AddressModel address) async {
    try {
      if (address.id == null) return Result.failure(ValidationFailure('ID Alamat tidak ditemukan'));
      
      if (address.isDefault) {
        await _clearDefault();
      }
      await _addressRepository.updateAddress(address.id!, address.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memperbarui alamat: $e'));
    }
  }

  Future<Result<void>> deleteAddress(String id) async {
    try {
      await _addressRepository.deleteAddress(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal menghapus alamat: $e'));
    }
  }

  Future<Result<void>> setDefaultAddress(String id) async {
    try {
      await _clearDefault();
      await _addressRepository.updateAddress(id, {'isDefault': true});
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal mengatur alamat utama: $e'));
    }
  }

  Future<Result<AddressModel?>> getDefaultAddress() async {
    try {
      final query = await _addressRepository.getDefaultAddresses();
      if (query.docs.isNotEmpty) {
        return Result.success(AddressModel.fromMap(
          query.docs.first.id, 
          query.docs.first.data(),
        ));
      }
      
      // If no default, try getting the first one
      final all = await _addressRepository.getFirstAddress();
      if (all.docs.isNotEmpty) {
        return Result.success(AddressModel.fromMap(
          all.docs.first.id, 
          all.docs.first.data(),
        ));
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Gagal memuat alamat utama: $e'));
    }
  }

  Future<void> _clearDefault() async {
    final query = await _addressRepository.getDefaultAddresses();
    for (var doc in query.docs) {
      await _addressRepository.updateAddress(doc.id, {'isDefault': false});
    }
  }
}
