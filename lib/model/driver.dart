import 'dart:io';

class Driver {
  final int id;
  final String status;
  final String licenseNo;
  final String? licenseFile;
  final String? remark;
  final int sysUserID;
  final int companySysUserID;
  final String? name;
  final String? phone;
  final String? email;
  final String? nricNo;
  final String? imgNric;
  final String? imgProfile;
  final File? fileDrivingLicense;
  //final File? fileNric;
  //final File? fileProfile;


  Driver({
    required this.id,
    required this.status,
    required this.licenseNo,
    this.licenseFile,
    this.remark,
    required this.sysUserID,
    required this.companySysUserID,
    this.name,
    this.phone,
    this.email,
    this.nricNo,
    this.imgNric,
    this.imgProfile,
    this.fileDrivingLicense,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'nricNo': nricNo,
    'licenseNo': licenseNo,
    'status': status,
    'licenseFile': licenseFile,
    'remark': remark,
    'sysUserID': sysUserID,
    'companySysUserID': companySysUserID,
  };

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      status: json['status'],
      licenseNo: json['licenseNo'],
      licenseFile: json['licenseFile'],
      remark: json['remark'],
      sysUserID: json['sysUserID'],
      companySysUserID: json['companySysUserID'],
      name: json['name'], // ✅ mapped
      phone: json['phone'], // ✅ mapped
      email: json['email'],
      nricNo: json['nricNo'],
      imgNric: json['imgNric'], // ✅ added
      imgProfile: json['imgProfile'], // ✅ mapped
      fileDrivingLicense: null,
    );
  }
}
