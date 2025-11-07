class LoginVM {
  final String phoneNo;
  final String password;

  LoginVM({required this.phoneNo, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'PhoneNo': phoneNo,
      'Password': password,
    };
  }
}
