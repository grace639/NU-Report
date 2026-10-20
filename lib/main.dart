import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/report_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');
  Intl.defaultLocale = 'th';
  runApp(
    // ลงทะเบียน Provider ไว้บนสุด ทุกหน้าจอด้านล่างเรียกใช้ได้
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const ReportApp(),
    ),
  );
}

class ReportApp extends StatelessWidget {
  const ReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NU Report',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // ฟังสถานะ login: ล็อกอินแล้วไปหน้าแรก ล็อกเอาต์แล้วกลับหน้า login อัตโนมัติ
      home: Consumer<AuthProvider>(
        builder: (_, auth, _) => auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
