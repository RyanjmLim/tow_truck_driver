import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/api/user_api.dart';
import '/model/sys_user.dart';
import '../app_theme.dart';
import 'otp_verification_reset.dart';
import '../app_constants.dart';

class ForgotPasswordPhonePage extends StatefulWidget {
  const ForgotPasswordPhonePage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPhonePage> createState() => _ForgotPasswordPhonePageState();
}

class _ForgotPasswordPhonePageState extends State<ForgotPasswordPhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  // normalize to digits only (e.g., "012-3456789" -> "0123456789")
  String _normalize(String input) => input.replaceAll(RegExp(r'[^\d]'), '');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final raw = _phoneCtrl.text.trim();
    final normalized = _normalize(raw);

    setState(() => _loading = true);

    // ✅ use your existing API name: getUserByPhoneNo
    final SysUser? user = await UserAPI.getUserByPhoneNo(normalized);

    setState(() => _loading = false);

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Phone number not found')),
      );
      return;
    }

    final masked = _maskPhone(user.phoneNo);
    final ok = await _confirmMaskedPhone(masked);
    if (!ok) return;

    // Generate 6-digit OTP
    final otpCode = (Random().nextInt(900000) + 100000).toString();

    // Send SMS (same style as teammate flow)
    final cleaned = _normalize(user.phoneNo);
    final encodedMsg = Uri.encodeComponent("Your verification code is $otpCode");
    final url = Uri.parse(
      "${AppConstants.BASE_URI}/Sms/Send/$cleaned/$encodedMsg/${AppConstants.SMS_API_KEY}",
    );

    setState(() => _loading = true);
    try {
      final res = await http.post(url);
      setState(() => _loading = false);

      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationResetPage(
              userId: user.id,
              phoneNumber: user.phoneNo,
              otpCode: otpCode,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to send OTP (${res.statusCode})')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error occurred while sending OTP')),
      );
    }
  }

  Future<bool> _confirmMaskedPhone(String masked) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.verified_user, color: MyAppColors.redDamask),
            SizedBox(width: 8),
            Text('Verify phone number'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("We’ll send a 6-digit code to:"),
            const SizedBox(height: 12),
            Text(masked, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    ) ??
        false;
  }

  String _maskPhone(String phone) {
    final digits = _normalize(phone);
    if (digits.length >= 4) {
      final last4 = digits.substring(digits.length - 4);
      return '••••••$last4';
    }
    return '••••••****';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MyAppColors.redDamask, MyAppColors.nobel],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text('  Reset Password',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('    Enter your phone number to receive an OTP.',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 28),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone, color: MyAppColors.codGray),
                            ),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                  : const Text('Continue'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Login')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
