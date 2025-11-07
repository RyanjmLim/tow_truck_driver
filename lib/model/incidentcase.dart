class IncidentCase {
  final int caseID;
  final DateTime timeStamp;
  final String type;
  final String location;
  final String status;

  final String? imgLocation;
  final String? descLocation;
  final String? imgFrontLeft;
  final String? imgFrontRight;
  final String? imgBottomLeft;
  final String? imgBottomRight;
  final String? imgSideLeft;
  final String? imgSideRight;

  final String? alternateName;
  final String? alternateContact;
  final String? alternateRelationship;
  final String? remarkAssistant;
  final String? remarkAlternate;

  final bool needTow;
  final int? ackBy;

  final int? vehicleID;
  final int? towingPanelID;
  final int? workshopID;
  final int customerID;
  final String? customerName;

  final double longitude;
  final double latitude;

  final String? policeStationLocation;

  final String? proofAtBreakdownPhoto;
  final String? proofAtPoliceStationPhoto;
  final String? proofAtWorkshopPhoto;
  final String? proofWorkshopReceivedPhoto;

  final DateTime? arrivedAtBreakdownTime;
  final DateTime? arrivedAtPoliceStationTime;
  final DateTime? arrivedAtWorkshopTime;

  IncidentCase({
    required this.caseID,
    required this.timeStamp,
    required this.type,
    required this.location,
    required this.status,
    this.imgLocation,
    this.descLocation,
    this.imgFrontLeft,
    this.imgFrontRight,
    this.imgBottomLeft,
    this.imgBottomRight,
    this.imgSideLeft,
    this.imgSideRight,
    this.alternateName,
    this.alternateContact,
    this.alternateRelationship,
    this.remarkAssistant,
    this.remarkAlternate,
    required this.needTow,
    this.ackBy,
    this.vehicleID,
    this.towingPanelID,
    this.workshopID,
    required this.customerID,
    this.customerName,
    required this.longitude,
    required this.latitude,
    this.policeStationLocation,
    this.proofAtBreakdownPhoto,
    this.proofAtPoliceStationPhoto,
    this.proofAtWorkshopPhoto,
    this.proofWorkshopReceivedPhoto,
    this.arrivedAtBreakdownTime,
    this.arrivedAtPoliceStationTime,
    this.arrivedAtWorkshopTime,
  });

  factory IncidentCase.fromJson(Map<String, dynamic> json) {
    return IncidentCase(
      caseID: json['caseID'],
      timeStamp: DateTime.parse(json['timeStamp']),
      type: json['type'],
      location: json['location'],
      status: json['status'],
      imgLocation: json['imgLocation'],
      descLocation: json['descLocation'],
      imgFrontLeft: json['imgFrontLeft'],
      imgFrontRight: json['imgFrontRight'],
      imgBottomLeft: json['imgBottomLeft'],
      imgBottomRight: json['imgBottomRight'],
      imgSideLeft: json['imgSideLeft'],
      imgSideRight: json['imgSideRight'],
      alternateName: json['alternateName'],
      alternateContact: json['alternateContact'],
      alternateRelationship: json['alternateRelationship'],
      remarkAssistant: json['remarkAssistant'],
      remarkAlternate: json['remarkAlternate'],
      needTow: (json['needTow'] ?? 0) == 1,
      ackBy: json['ackBy'],
      vehicleID: json['vehicleID'],
      towingPanelID: json['towingPanelID'],
      workshopID: json['workshopID'],
      customerID: json['customerID'],
      customerName: json['customerName'],
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      policeStationLocation: json['policeStationLocation'],
      proofAtBreakdownPhoto: json['proofAtBreakdownPhoto'],
      proofAtPoliceStationPhoto: json['proofAtPoliceStationPhoto'],
      proofAtWorkshopPhoto: json['proofAtWorkshopPhoto'],
      proofWorkshopReceivedPhoto: json['proofWorkshopReceivedPhoto'],
      arrivedAtBreakdownTime: json['arrivedAtBreakdownTime'] != null
          ? DateTime.tryParse(json['arrivedAtBreakdownTime'])
          : null,
      arrivedAtPoliceStationTime: json['arrivedAtPoliceStationTime'] != null
          ? DateTime.tryParse(json['arrivedAtPoliceStationTime'])
          : null,
      arrivedAtWorkshopTime: json['arrivedAtWorkshopTime'] != null
          ? DateTime.tryParse(json['arrivedAtWorkshopTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caseID': caseID,
      'timeStamp': timeStamp.toIso8601String(),
      'type': type,
      'location': location,
      'status': status,
      'imgLocation': imgLocation,
      'descLocation': descLocation,
      'imgFrontLeft': imgFrontLeft,
      'imgFrontRight': imgFrontRight,
      'imgBottomLeft': imgBottomLeft,
      'imgBottomRight': imgBottomRight,
      'imgSideLeft': imgSideLeft,
      'imgSideRight': imgSideRight,
      'alternateName': alternateName,
      'alternateContact': alternateContact,
      'alternateRelationship': alternateRelationship,
      'remarkAssistant': remarkAssistant,
      'remarkAlternate': remarkAlternate,
      'needTow': needTow ? 1 : 0,
      'ackBy': ackBy,
      'vehicleID': vehicleID,
      'towingPanelID': towingPanelID,
      'workshopID': workshopID,
      'customerID': customerID,
      'customerName': customerName,
      'longitude': longitude,
      'latitude': latitude,
      'policeStationLocation': policeStationLocation,
      'proofAtBreakdownPhoto': proofAtBreakdownPhoto,
      'proofAtPoliceStationPhoto': proofAtPoliceStationPhoto,
      'proofAtWorkshopPhoto': proofAtWorkshopPhoto,
      'proofWorkshopReceivedPhoto': proofWorkshopReceivedPhoto,
      'arrivedAtBreakdownTime': arrivedAtBreakdownTime?.toIso8601String(),
      'arrivedAtPoliceStationTime': arrivedAtPoliceStationTime?.toIso8601String(),
      'arrivedAtWorkshopTime': arrivedAtWorkshopTime?.toIso8601String(),
    };
  }
}
