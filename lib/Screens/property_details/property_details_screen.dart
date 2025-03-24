import 'package:flutter/material.dart';
import 'package:gis/Screens/property_details/widgets/contact_actions.dart';
import 'package:gis/Screens/property_details/widgets/property_details_section.dart';
import 'package:gis/Screens/property_details/widgets/property_image_switcher.dart';
import 'package:gis/Screens/property_details/widgets/property_info_section.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final String propertyId;

  const PropertyDetailsScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBar(
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  title: Text(
                    'الرجوع إلى القائمة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                PropertyImageSwitcher(propertyId: propertyId),
                PropertyInfoSection(),
                PropertyDetailsSection(),
                ContactActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
