class SysUser {
  final int id;
  final String fullName;
  final String phoneNo;
  final String password;
  final String email;
  final String accStatus;
  final String userType;
  final String? alias;
  final String? nricNo;
  final String? state;
  final String? country;
  final String? occupation;
  final String? imgNric;
  final String? imgProfile;
  final String? remark;
  final String? gender;
  final DateTime? timestamp;
  final DateTime? lastUpdate;

  SysUser({
    required this.id,
    required this.fullName,
    required this.phoneNo,
    required this.password,
    required this.email,
    required this.accStatus,
    required this.userType,
    this.alias,
    this.nricNo,
    this.state,
    this.country,
    this.occupation,
    this.imgNric,
    this.imgProfile,
    this.remark,
    this.gender,
    this.timestamp,
    this.lastUpdate,
  });

  factory SysUser.fromJson(Map<String, dynamic> json) {
    return SysUser(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      accStatus: json['accStatus'] ?? '',
      userType: json['userType'] ?? '',
      alias: json['alias'],
      nricNo: json['nricNo'],
      state: json['state'],
      country: json['country'],
      occupation: json['occupation'],
      imgNric: json['imgNric'],
      imgProfile: json['imgProfile'],
      remark: json['remark'],
      gender: json['gender']?.toString(), // backend sends `char?`
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
      lastUpdate: json['lastUpdate'] != null ? DateTime.tryParse(json['lastUpdate']) : null,
    );
  }
}
