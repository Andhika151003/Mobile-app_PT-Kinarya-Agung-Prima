import 'package:ecommerce/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../controllers/address_controller.dart';
import '../models/address_model.dart';

class AddressFormView extends StatefulWidget {
  final AddressModel? address;
  const AddressFormView({super.key, this.address});

  @override
  State<AddressFormView> createState() => _AddressFormViewState();
}

class _AddressFormViewState extends State<AddressFormView> {
  final _formKey = GlobalKey<FormState>();
  final AddressController _controller = AddressController();

  late TextEditingController _labelController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _nameController = TextEditingController(text: widget.address?.recipientName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.address?.fullAddress ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final address = AddressModel(
      id: widget.address?.id,
      label: _labelController.text.trim(),
      recipientName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      fullAddress: _addressController.text.trim().replaceAll('\n', ' '),
      isDefault: _isDefault,
    );

    try {
      if (widget.address == null) {
        await _controller.addAddress(address);
      } else {
        await _controller.updateAddress(address);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil disimpan'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan alamat: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.address == null ? 'Tambah Alamat' : 'Edit Alamat',
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Label Alamat (misal: Rumah, Kantor)', 'Masukkan label', _labelController, maxLength: 30),
              _buildTextField('Nama Penerima', 'Masukkan nama penerima', _nameController, maxLength: 50),
              _buildTextField('Nomor Telepon', 'Masukkan nomor telepon', _phoneController, isPhone: true, maxLength: 15),
              _buildTextField('Alamat Lengkap', 'Masukkan alamat lengkap', _addressController, maxLines: 3, maxLength: 200),
              
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isDefault = val ?? false),
                  ),
                  const Text('Jadikan Alamat Utama', style: TextStyle(fontSize: 14)),
                ],
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan Alamat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isPhone = false, int maxLines = 1, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: isPhone ? TextInputType.phone : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
          textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            counterText: "", // Hide the counter for cleaner look
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
