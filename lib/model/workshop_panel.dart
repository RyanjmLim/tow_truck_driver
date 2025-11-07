class WorkshopPanel {
  final String? address;
  final String? companyName;
  final String? companyPhoneNo;
  final String? companyLogo;

  WorkshopPanel({
    this.address,
    this.companyName,
    this.companyPhoneNo,
    this.companyLogo,
  });

  factory WorkshopPanel.fromJson(Map<String, dynamic> json) {
    return WorkshopPanel(
      address: json['address'],
      companyName: json['companyName'],
      companyPhoneNo: json['companyPhoneNo'],
      companyLogo: json['companyLogo'],
    );
  }
}
