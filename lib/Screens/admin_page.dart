import 'package:flutter/material.dart';
import 'package:gis/Screens/admin_land_auctions_search.dart';
import 'package:gis/Screens/update_basins.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminPage extends StatelessWidget {
  void _showNotificationDialog(BuildContext context, String title) {
    TextEditingController _inputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: "أدخل الإشعار هنا",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                print("إرسال إشعار: ${_inputController.text}");
                Navigator.pop(context);
              },
              child: Text("إرسال"),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            const Color.fromARGB(253, 254, 251, 251), // Light Gray Background
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(170, 13, 2, 25),
                  const Color.fromARGB(255, 5, 16, 25),
                  const Color.fromARGB(188, 40, 9, 29)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AppBar(
              title: Text('لوحة تحكم المسؤول',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            _buildCard(context, Icons.gavel, "المزادات المنشورة",
                LandsAdminAuctionsSearch()),
            _buildCard(context, Icons.pause_circle_filled, "المزادات المعلقة",
                PendingAuctionsPage()),
            _buildCard(context, Icons.cancel, "المزادات المرفوضة",
                RejectedAuctionsPage()),
            _buildCard(context, Icons.map, "تحديث الأحواض", UpdatePoolsPage()),
            _buildCardWithDialog(context, Icons.notifications, "الإشعارات"),
            _buildCardWithDialog(
                context, Icons.send, "إرسال إشعار لجميع التجار"),
            _buildCardWithDialog(
                context, Icons.mark_email_read, "إرسال إشعار للمتصفحين"),
            _buildCard(context, Icons.verified_user, "التحقق من طلبات التجار",
                TradersVerificationPage()),
            _buildCard(context, Icons.update, "تحديث معلومات التجار",
                UpdateTradersInfoPage()),
            _buildProgressBar(), // Custom Progress Bar
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, IconData icon, String title, Widget page) {
    return Card(
      color: Colors.white, // White Background
      elevation: 3, // Light Shadow Effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: TextStyle(fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.teal),
        onTap: () => _navigateTo(context, page),
      ),
    );
  }

  Widget _buildCardWithDialog(
      BuildContext context, IconData icon, String title) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: TextStyle(fontSize: 16)),
        trailing: Icon(Icons.notifications, size: 18, color: Colors.teal),
        onTap: () => _showNotificationDialog(context, title),
      ),
    );
  }

  // Custom Progress Bar with 3-color Gradient
  Widget _buildProgressBar() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.green, Colors.teal], // 3-color Gradient
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

// صفحات الإدخال والتحديث الأخرى

class PublishedAuctionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("المزادات المنشورة"), backgroundColor: Colors.teal),
      body: Center(child: Text("صفحة المزادات المنشورة")),
    );
  }
}

class PendingAuctionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("المزادات المعلقة"), backgroundColor: Colors.teal),
      body: Center(child: Text("صفحة المزادات المعلقة")),
    );
  }
}

class RejectedAuctionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("المزادات المرفوضة"), backgroundColor: Colors.teal),
      body: Center(child: Text("صفحة المزادات المرفوضة")),
    );
  }
}

class TradersVerificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("التحقق من طلبات التجار"), backgroundColor: Colors.teal),
      body: Center(child: Text("صفحة التحقق من طلبات التجار")),
    );
  }
}

class UpdateTradersInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("تحديث معلومات التجار"), backgroundColor: Colors.teal),
      body: Center(child: Text("صفحة تحديث معلومات التجار")),
    );
  }
}
