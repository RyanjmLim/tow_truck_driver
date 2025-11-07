class IncidentCaseOwnerDetails {
  final String imgCar;
  final String plateNo;
  final String brand;
  final String colour;
  final int manuYear;
  final String fullName;
  final String phoneNo;
  final String alternateName;
  final String alternateContact;
  final String alternateRelationship;

  IncidentCaseOwnerDetails({
    required this.imgCar,
    required this.plateNo,
    required this.brand,
    required this.colour,
    required this.manuYear,
    required this.fullName,
    required this.phoneNo,
    required this.alternateName,
    required this.alternateContact,
    required this.alternateRelationship,
  });

  factory IncidentCaseOwnerDetails.fromJson(Map<String, dynamic> json) {
    return IncidentCaseOwnerDetails(
      imgCar: json['imgCar'] ?? '',
      plateNo: json['plateNo'] ?? '',
      brand: json['brand'] ?? '',
      colour: json['colour'] ?? '',
      manuYear: json['manuYear'] ?? 0,
      fullName: json['fullName'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      alternateName: json['alternateName'] ?? '',
      alternateContact: json['alternateContact'] ?? '',
      alternateRelationship: json['alternateRelationship'] ?? '',
    );
  }
}
