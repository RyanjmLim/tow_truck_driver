class DriverLogStatusUpdate {
  final int driverLogID;
  final String status;

  DriverLogStatusUpdate({
    required this.driverLogID,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'driverLogID': driverLogID,
    'status': status,
  };
}
