class DriverCaseInfo {
  final int driverLogID;
  final int caseID;
  final int driverID;
  final String status;
  final String? serviceType;
  final String type;
  final String remark;
  final String location;
  final DateTime timeStamp;

  DriverCaseInfo({
    required this.driverLogID,
    required this.caseID,
    required this.driverID,
    required this.status,
    required this.serviceType,
    required this.type,
    required this.remark,
    required this.location,
    required this.timeStamp,
  });

  factory DriverCaseInfo.fromJson(Map<String, dynamic> json) {
    return DriverCaseInfo(
      driverLogID: json['driverLogID'],
      caseID: json['caseID'],
      driverID: json['driverID'],
      status: json['status'] ?? '',
      serviceType: json['serviceType'],
      type: json['type'] ?? '',
      remark: json['remark'] ?? '',
      location: json['location'] ?? '—',
      timeStamp: json['timeStamp'] != null
          ? DateTime.parse(json['timeStamp'])
          : DateTime.now(),
    );
  }
}

