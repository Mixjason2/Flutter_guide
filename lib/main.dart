import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/joblist_screen.dart'; // <--- นำเข้าไฟล์ home_screen

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // <--- ปิดแถบ Debug banner
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/joblist': (context) => JobsListPage(), // <--- เพิ่มตรงนี้
      },
    );
  }
}
