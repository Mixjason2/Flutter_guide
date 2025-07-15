import 'package:flutter/material.dart';
import 'global_images.dart';  // import ตัว global image

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Color(0xFF2D3E92),
        child: Column(
          children: [
            DrawerHeader(
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.white),
              title: Text("Calendar", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, "/calendar");
              },
            ),
            ListTile(
              leading: Icon(Icons.work, color: Colors.white),
              title: Text("Jobs List", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, "/joblist");
              },
            ),
            Spacer(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Log Out", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Color(0xFF2D3E92),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            testSvgWidget,  // เรียกใช้จาก global variable
          ],
        ),
      ),
      body: widget.child,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              testSvgWidget,  // เรียกใช้จาก global variable
              Text(
                "© 2014–2023 DTH Travel. All Rights Reserved.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
