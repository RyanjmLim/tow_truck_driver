class DriverLog {
  final int driverLogID;
  final DateTime timeStamp;
  final int driverID;
  final int vehicleID;
  final int companySysUserID;
  final String? status;
  final int caseID;
  final DateTime? completeTime;
  final double? longitude;
  final double? latitude;
  final DateTime? eta;

  DriverLog({
    required this.driverLogID,
    required this.timeStamp,
    required this.driverID,
    required this.vehicleID,
    required this.companySysUserID,
    this.status,
    required this.caseID,
    this.completeTime,
    this.longitude,
    this.latitude,
    this.eta,
  });

  factory DriverLog.fromJson(Map<String, dynamic> json) {
    return DriverLog(
      driverLogID: json['driverLogID'],
      timeStamp: DateTime.parse(json['timeStamp']),
      driverID: json['driverID'],
      vehicleID: json['vehicleID'],
      companySysUserID: json['companySysUserID'],
      status: json['status'],
      caseID: json['caseID'],
      completeTime: json['completeTime'] != null
          ? DateTime.tryParse(json['completeTime'])
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      eta: json['eta'] != null
          ? DateTime.tryParse(json['eta'])
          : null,
    );
  }
}
