import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'view/login.dart';
import 'view/dashboard.dart';
import '/api/user_api.dart';
import '/model/sys_user.dart';

// --- Persist login helpers ---
Future<void> saveLoginState(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  await prefs.setString('userId', userId);
}

Future<void> clearLoginState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userId = prefs.getString('userId');

  runApp(MyApp(isLoggedIn: isLoggedIn, userId: userId));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userId;

  const MyApp({super.key, required this.isLoggedIn, this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'Bantu Pandu',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: isLoggedIn && userId != null
          ? SplashLoader(userId: userId!)
          : const PanelLoginPage(),
    );
  }
}

// --- Small splash loader to fetch SysUser from API ---
class SplashLoader extends StatefulWidget {
  final String userId;
  const SplashLoader({super.key, required this.userId});

  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> {
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final SysUser? user = await UserAPI.getUserById(int.parse(widget.userId));
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage(sysUser: user)),
        );
      } else {
        // If user fetch failed, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PanelLoginPage()),
        );
      }
    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PanelLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
