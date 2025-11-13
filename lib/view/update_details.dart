import 'package:flutter/material.dart';
import '/api/user_api.dart';
import '/model/sys_user.dart';
import '../app_theme.dart';
import '../main.dart' show clearLoginState;
import 'login.dart';
import '../services/FirebaseNotificationService.dart';

class UpdateDetailsPage extends StatefulWidget {
  final int userId;

  const UpdateDetailsPage({super.key, required this.userId});

  @override
  State<UpdateDetailsPage> createState() => _UpdateDetailsPageState();
}

class _UpdateDetailsPageState extends State<UpdateDetailsPage> {
  // Forms
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Profile controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Password controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final FocusNode _newPwdFocus = FocusNode();
  final FocusNode _confirmPwdFocus = FocusNode();

  // UI state
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _passwordSectionExpanded = false;
  bool _currentVerified = false;
  bool _isVerifying = false;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  SysUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPwdFocus.dispose();
    _confirmPwdFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await UserAPI.getUserById(widget.userId);
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user profile'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _user = user;
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phoneNo;
      _emailController.text = user.email;
    });
  }

  // ---------------- Profile Save ----------------
  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    if (_user == null) return;

    setState(() => _isSavingProfile = true);

    final payload = {
      "id": _user!.id,
      "fullName": _fullNameController.text.trim(),
      "alias": _user!.alias ?? '',
      "nricNo": _user!.nricNo ?? '',
      "phoneNo": _phoneController.text.trim(),
      "email": _emailController.text.trim(),
      "gender": _user!.gender ?? '',
      "state": _user!.state ?? '',
      "country": _user!.country ?? '',
      "occupation": _user!.occupation ?? '',
      "accStatus": _user!.accStatus,
      "userType": _user!.userType,
      "remark": _user!.remark ?? '',
    };

    final ok = await UserAPI.updateUserDetails(payload);
    if (!mounted) return;
    setState(() => _isSavingProfile = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------- Verify Existing Password ----------------
  Future<void> _verifyCurrentPassword() async {
    if (_user == null) return;
    final current = _currentPasswordController.text;
    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your existing password'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _currentVerified = false;
    });

    final verified = await UserAPI.verifyByPhone(_user!.phoneNo, current);
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _currentVerified = verified != null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentVerified ? 'Existing password verified' : 'Existing password is incorrect'),
        backgroundColor: _currentVerified ? Colors.green : Colors.red,
      ),
    );

    if (_currentVerified) {
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      await Future.delayed(const Duration(milliseconds: 50));
      _newPwdFocus.requestFocus();
    }
  }

  // ---------------- Save New Password ----------------
  Future<void> _saveNewPassword() async {
    if (_user == null) return;
    if (!_currentVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your existing password first'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_passwordFormKey.currentState!.validate()) return;

    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirmation do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSavingPassword = true);

    final payload = {
      "id": _user!.id,
      "fullName": _user!.fullName,
      "alias": _user!.alias ?? '',
      "nricNo": _user!.nricNo ?? '',
      "phoneNo": _user!.phoneNo,
      "email": _user!.email,
      "gender": _user!.gender ?? '',
      "state": _user!.state ?? '',
      "country": _user!.country ?? '',
      "occupation": _user!.occupation ?? '',
      "accStatus": _user!.accStatus,
      "userType": _user!.userType,
      "remark": _user!.remark ?? '',
      "password": newPass,
    };

    final ok = await UserAPI.updateUserDetails(payload);
    if (!mounted) return;
    setState(() => _isSavingPassword = false);

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _currentVerified = false;
        _passwordSectionExpanded = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password update failed. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------- BACK BUTTON --------
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Update My Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // -------- PROFILE CARD --------
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _readonlyField(label: 'Full Name', value: _fullNameController.text),
                          const SizedBox(height: 16),
                          _editField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Please enter Phone Number';
                              if (s.length < 6) return 'Phone Number looks too short';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _editField(
                            label: 'Email Address',
                            controller: _emailController,
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Please enter Email Address';
                              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                              return ok ? null : 'Enter a valid email';
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isSavingProfile ? null : _saveProfile,
                            child: _isSavingProfile
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Text('Save Profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // -------- PASSWORD CARD --------
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_reset),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Change Password',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordSectionExpanded = !_passwordSectionExpanded;
                                  if (!_passwordSectionExpanded) {
                                    _currentVerified = false;
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  }
                                });
                              },
                              icon: Icon(_passwordSectionExpanded ? Icons.expand_less : Icons.expand_more),
                            ),
                          ],
                        ),

                        if (_passwordSectionExpanded) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Step 1: Verify existing password
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _passwordField(
                                  label: 'Existing Password',
                                  controller: _currentPasswordController,
                                  obscure: _obscureCurrent,
                                  onToggleObscure: () =>
                                      setState(() => _obscureCurrent = !_obscureCurrent),
                                  helperText: _currentVerified
                                      ? 'Verified ✓ You can now set a new password.'
                                      : 'Enter your existing password and tap Verify',
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyCurrentPassword,
                                child: _isVerifying
                                    ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Text('Verify'),
                              ),
                            ],
                          ),

                          // Step 2: Show new fields only after verification
                          if (_currentVerified) ...[
                            const SizedBox(height: 16),
                            Form(
                              key: _passwordFormKey,
                              child: Column(
                                children: [
                                  _passwordField(
                                    label: 'New Password',
                                    controller: _newPasswordController,
                                    obscure: _obscureNew,
                                    onToggleObscure: () =>
                                        setState(() => _obscureNew = !_obscureNew),
                                    focusNode: _newPwdFocus,
                                    validator: (v) {
                                      final s = (v ?? '').trim();
                                      if (s.isEmpty) return 'Please enter a new password';
                                      if (s.length < 8) return 'Password must be at least 8 characters';
                                      if (s == _currentPasswordController.text) {
                                        return 'New password must be different from existing password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _passwordField(
                                    label: 'Confirm New Password',
                                    controller: _confirmPasswordController,
                                    obscure: _obscureConfirm,
                                    onToggleObscure: () =>
                                        setState(() => _obscureConfirm = !_obscureConfirm),
                                    focusNode: _confirmPwdFocus,
                                    validator: (v) {
                                      final s = (v ?? '').trim();
                                      if (s.isEmpty) return 'Please confirm your new password';
                                      if (s != _newPasswordController.text)
                                        return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isSavingPassword ? null : _saveNewPassword,
                                      icon: const Icon(Icons.check),
                                      label: _isSavingPassword
                                          ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                          : const Text('Save New Password'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // -------- LOGOUT --------
                // -------- LOGOUT --------
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                // 🔴 1. Unregister FCM token
                                await FirebaseNotificationService.unregisterToken();

                                // 🔴 2. Clear login state (SharedPreferences, provider, etc.)
                                await clearLoginState();

                                if (!mounted) return;

                                // 🔴 3. Navigate to login & remove all previous routes
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PanelLoginPage()),
                                      (route) => false,
                                );
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

  // ---------------- Widgets ----------------
  Widget _readonlyField({required String label, required String value}) {
    return TextFormField(
      readOnly: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade300,
        prefixIcon: const Icon(Icons.person),
      ),
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    );
  }

  Widget _editField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ??
              (v) => (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
    String? helperText,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleObscure,
        ),
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
