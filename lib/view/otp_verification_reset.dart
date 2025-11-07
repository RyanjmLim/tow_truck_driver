import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_constants.dart';
import '../app_theme.dart';
import 'reset_password_final.dart';

class OtpVerificationResetPage extends StatefulWidget {
  final int userId;
  final String phoneNumber;
  final String otpCode;

  const OtpVerificationResetPage({
    Key? key,
    required this.userId,
    required this.phoneNumber,
    required this.otpCode,
  }) : super(key: key);

  @override
  State<OtpVerificationResetPage> createState() => _OtpVerificationResetPageState();
}

class _OtpVerificationResetPageState extends State<OtpVerificationResetPage> {
  late String _currentOtp;
  final List<TextEditingController> _boxes = List.generate(6, (_) => TextEditingController());
  Timer? _timer;
  int _seconds = 300;
  bool _canResend = false;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.otpCode;
    _startTimer();
  }

  void _startTimer() {
    _canResend = false;
    _expired = false;
    _seconds = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
        setState(() {
          _canResend = true;
          _expired = true;
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String _fmt(int s) => "${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}";

  Future<void> _resend() async {
    final newOtp = (Random().nextInt(900000) + 100000).toString();
    setState(() => _currentOtp = newOtp);

    final cleaned = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final msg = Uri.encodeComponent("Your verification code is $newOtp");
    final url = Uri.parse("${AppConstants.BASE_URI}/Sms/Send/$cleaned/$msg/${AppConstants.SMS_API_KEY}");

    try {
      final r = await http.post(url);
      if (r.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP resent")));
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to resend OTP")));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error while resending")));
    }
  }

  bool _allFilled() => _boxes.every((c) => c.text.isNotEmpty);

  void _verify() {
    if (_expired) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP expired. Please resend.")));
      return;
    }
    final entered = _boxes.map((c) => c.text).join();
    if (entered == _currentOtp) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordFinalPage(userId: widget.userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _boxes) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [MyAppColors.redDamask, MyAppColors.nobel],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset('assets/images/logo.png', height: 80),
                const SizedBox(height: 24),
                const Text('Verify OTP',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 8),
                Text('A 6-digit code was sent to ${widget.phoneNumber}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: _boxes[i],
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true, fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) FocusScope.of(context).nextFocus();
                            if (v.isEmpty && i > 0) FocusScope.of(context).previousFocus();
                            if (_allFilled()) Future.delayed(const Duration(milliseconds: 80), _verify);
                          },
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 14),
                Text(_expired ? "Code expired" : "Code expires in ${_fmt(_seconds)}",
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(onPressed: _verify, child: const Text('Verify')),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _canResend ? _resend : null,
                  child: Text(_canResend ? "Resend Code" : "Resend in ${_fmt(_seconds)}",
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
