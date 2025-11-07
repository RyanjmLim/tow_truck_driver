import 'package:flutter/material.dart';
import '/api/user_api.dart';
import 'dashboard.dart';
import '/model/login_vm.dart';
import '/model/sys_user.dart';
import '../app_theme.dart';
import '../main.dart' show saveLoginState;
import 'forgot_password_phone.dart';

class PanelLoginPage extends StatefulWidget {
  const PanelLoginPage({Key? key}) : super(key: key);

  @override
  State<PanelLoginPage> createState() => _PanelLoginPageState();
}

class _PanelLoginPageState extends State<PanelLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePass = true;

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
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Driver App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Please enter your login credentials below.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.person, color: MyAppColors.codGray),
                            ),
                            style: const TextStyle(color: MyAppColors.codGray),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter your phone number'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: MyAppColors.codGray),
                              suffixIcon: TextButton(
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                child: Text(
                                  _obscurePass ? 'Show' : 'Hide',
                                  style: const TextStyle(color: MyAppColors.redDamask),
                                ),
                              ),
                            ),
                            style: const TextStyle(color: MyAppColors.codGray),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter password'
                                : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final loginData = LoginVM(
                                    phoneNo: _phoneController.text,
                                    password: _passwordController.text,
                                  );


                                  final result = await UserAPI.verifyByPhone(
                                    loginData.phoneNo,
                                    loginData.password,
                                  );

                                  if (result != null && result['id'] != null) {

                                    final SysUser? user = await UserAPI.getUserById(result['id']);

                                    if (user != null) {
                                      if (user.userType.toLowerCase() == 'd') {

                                        await saveLoginState(user.id.toString());


                                        if (!context.mounted) return;
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => DashboardPage(sysUser: user)),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Only drivers are allowed to login here")),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Unable to load user details")),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Invalid phone number or password")),
                                    );
                                  }
                                }
                              },

                              child: const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 24),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordPhonePage()),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: MyAppColors.redDamask,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '© Bantu Pandu. All rights reserved.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
