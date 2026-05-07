class AddressModel {
  final String? id;
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'fullAddress': fullAddress,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromMap(String id, Map<String, dynamic> map) {
    return AddressModel(
      id: id,
      label: map['label'] ?? '',
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      fullAddress: map['fullAddress'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? fullAddress,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullAddress: fullAddress ?? this.fullAddress,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
