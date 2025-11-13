class Vehicle {
  final int id;
  final String brand;
  final String model;
  final String plate;
  final String colour;
  final int? manuYear;
  final String vehicleUse;
  final String registrationCard;
  final String imgCar;
  final int userId;
  final String remark;
  final bool? isVerified;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.plate,
    required this.colour,
    this.manuYear,
    required this.vehicleUse,
    required this.registrationCard,
    required this.imgCar,
    required this.userId,
    required this.remark,
    this.isVerified,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      userId: json['userId'] ?? 0,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      plate: json['plateNo'] ?? '',
      colour: json['colour'] ?? '',
      manuYear: json['manuYear'], // already nullable
      vehicleUse: json['vehicleUse'] ?? '',
      registrationCard: json['registrationCard'] ?? '',
      imgCar: json['imgCar'] ?? '',
      remark: json['remark'] ?? '',
      isVerified: json['isVerified'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleID': id,
      'brand': brand,
      'model': model,
      'plateNo': plate,
      'colour': colour,
      'manuYear': manuYear,
      'vehicleUse': vehicleUse,
      'registrationCard': registrationCard,
      'imgCar': imgCar,
      'userId': userId,
      'remark': remark,
      'isVerified': isVerified,
    };
  }
}
