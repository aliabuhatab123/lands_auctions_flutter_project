import 'package:flutter/material.dart';

class PropertyInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'منذ 13 ساعة',
              style: TextStyle(
                color: Color(0xFF7C7C7C),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '34 ألف  ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'دينار أردني ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.favorite_border,
                  color: Color(0xFF7C7C7C),
                  size: 24,
                ),
              ],
            ),
            // Text(
            //   'قطعة الأرض في طمون، الحوض: الزيتون الشرقي، حي حبول ذياب',
            //   style: TextStyle(
            //     color: Color(0xFF7C7C7C),
            //     fontSize: 14,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
