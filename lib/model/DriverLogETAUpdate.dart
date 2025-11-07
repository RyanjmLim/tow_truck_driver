class DriverLogETAUpdate {
  final int driverLogID;
  final DateTime eta;

  DriverLogETAUpdate({
    required this.driverLogID,
    required this.eta,
  });

  Map<String, dynamic> toJson() {
    return {
      'driverLogID': driverLogID,
      'eta': eta.toIso8601String(),
    };
  }
}
