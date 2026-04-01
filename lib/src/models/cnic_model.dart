class CnicModel {
  String? name;
  String? fatherName;
  String? cnicNumber;
  String? dob;
  String? expiry;
  String? address;

  CnicModel({
    this.name,
    this.fatherName,
    this.cnicNumber,
    this.dob,
    this.expiry,
    this.address,
  });

  factory CnicModel.fromJson(Map<String, dynamic> json) {
    return CnicModel(
      name: json['name'],
      fatherName: json['fatherName'],
      cnicNumber: json['cnicNumber'],
      dob: json['dob'],
      expiry: json['expiry'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fatherName': fatherName,
      'cnicNumber': cnicNumber,
      'dob': dob,
      'expiry': expiry,
      'address': address,
    };
  }

  @override
  String toString() {
    return 'CnicModel(name: $name, fatherName: $fatherName, cnicNumber: $cnicNumber, dob: $dob, expiry: $expiry, address: $address)';
  }
}
