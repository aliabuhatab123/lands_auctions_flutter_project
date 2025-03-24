import 'package:flutter/material.dart';
import 'package:gis/Screens/Add_Property/add_prop_page_a.dart';
import 'package:gis/Screens/My_Properties/my_prop.dart';
import 'package:gis/Screens/login_page.dart';
import 'package:gis/Screens/home_page.dart'; // Assuming this is the import for HomePage
import 'package:gis/Screens/lands_auctions_search.dart'; // Assuming this is the import for LandsAuctionsSearch

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _currentIndex = 1; // Default to "حسابي" tab

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // المزادات
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LandsAuctionsSearch()),
        );
        break;
      case 1: // حسابي (stay on this screen)
        break;
      case 2: // الخريطة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              jsonLands: '',
              jsonNeighborhood: '',
              landNumber: '',
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'حسابي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Cairo',
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // _buildProfileSection(),
              _buildMainActions(context),
              _buildSecondaryActions(context),
            ],
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNavigationBar(),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'محمد أحمد',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            'mohammad@example.com',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('المزادات', '12'),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              _buildStatItem('العقارات', '5'),
              Container(height: 30, width: 1, color: Colors.grey[300]),
              _buildStatItem('المفضلة', '8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إدارة العقارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  Icons.add_home_work,
                  'إضافة عقار',
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddPropertyScreen()),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context,
                  Icons.home_work,
                  'عقاراتي',
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyPropertiesScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 16),
          _buildSettingsButton(
            context,
            Icons.settings,
            'إعدادات الحساب',
            () {},
          ),
          _buildSettingsButton(
            context,
            Icons.notifications,
            'الإشعارات',
            () {},
          ),
          _buildSettingsButton(
            context,
            Icons.help,
            'المساعدة والدعم',
            () {},
          ),
          _buildSettingsButton(
            context,
            Icons.privacy_tip,
            'سياسة الخصوصية',
            () {},
          ),
          _buildSettingsButton(
            context,
            Icons.logout,
            'تسجيل الخروج',
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            ),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: color ?? Colors.grey[800],
          fontFamily: 'Cairo',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color ?? Colors.grey[400],
      ),
    );
  }

  Widget _buildCustomBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 185, 89, 89), // Red
            const Color.fromARGB(221, 187, 0, 0), // Black
            const Color.fromARGB(255, 142, 57, 57), // Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color.fromARGB(
            0, 206, 193, 193), // Transparent to show gradient
        elevation: 0,
        selectedItemColor: const Color.fromARGB(255, 227, 216, 216),
        unselectedItemColor: const Color.fromARGB(179, 247, 247, 247),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: 'المزادات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'حسابي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'الخريطة',
          ),
        ],
      ),
    );
  }
}
