import 'package:flutter/material.dart';

class PropertyDetailsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(2),
              width: 400,
              height: 30,
              color: const Color.fromARGB(250, 249, 249, 249),
              child: Text(
                'تفاصيل قطعة الأرض',
                style: TextStyle(
                  color: Color.fromARGB(255, 8, 0, 0),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(2),
              width: 400,
              height: 250,
              color: const Color.fromARGB(37, 205, 202, 197),
              child: Column(
                children: [
                  _buildDetailRow('رقم القطعة', '25'),
                  _buildDetailRow('نوع القطعة', 'أرض بناء'),
                  _buildDetailRow('مساحة الأرض (متر مربع)', '2350'),
                  _buildDetailRow('اسم الحوض', 'الزيتون الشرقي'),
                  _buildDetailRow('اسم المالك', 'مصطفى محمد بشارات'),
                  _buildDetailRow('رقم الجوال', '0595787655'),
                ],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'هذه قطعة أرض في منطقة طمون تصنيف أ، وهي مناسبة للبناء بمساحة 2350 متر مربع. الطابو هو كوشان أصلي.',
                style: TextStyle(
                  color: Color(0xFF848484),
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.only(top: 4, bottom: 4, right: 8, left: 8),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Color(0xFF848484),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
