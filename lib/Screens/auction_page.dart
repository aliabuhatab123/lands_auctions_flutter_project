import 'package:flutter/material.dart';
import 'dart:async';

class AuctionPage extends StatefulWidget {
  final String town;
  final int index;

  const AuctionPage({super.key, required this.town, required this.index});

  @override
  _AuctionPageState createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  late Timer _timer;
  int _start = 60; // Timer starts from 60 seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (_start < 1) {
          timer.cancel();
        } else {
          _start--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'مزايدة قطعة الأرض',
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(
                      'assets/bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // Land Information
                Text(
                  'قطعة الأرض ${widget.town} ${widget.index}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'قطعة ارض 30 دونم بإطلالة جميلة وموقع مميز، فرصتك لتتملك في مدينة طوباس قطعة ارض المزيد من التفاصيل عن العقار داخل الاعلان. السعر و معلومات الاتصال مرفقة داخل الاعلان',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 26),

                // Timer for auction
                Text(
                  'باقي على المزاد: $_start ثانية',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
                const SizedBox(height: 20),

                // Land Information Table
                _buildLandInfo(),

                const SizedBox(height: 20),

                // Owner Contact Information Table

                const SizedBox(height: 20),

                // Bidding Section
                _buildBiddingSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Land Information table
  Widget _buildLandInfo() {
    return Container(
      width: double.infinity, // Full width
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.grey[300]!, width: 1), // Light gray border
        borderRadius: BorderRadius.circular(8),
      ),
      child: DataTable(
        columnSpacing: 20,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey[300]!, width: 1), // Light gray border
        ),
        columns: const <DataColumn>[
          DataColumn(
              label: Text('المعلومات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          DataColumn(
              label: Text('القيمة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        ],
        rows: <DataRow>[
          DataRow(cells: <DataCell>[
            DataCell(Text('رقم القطعة', style: TextStyle(fontSize: 16))),
            DataCell(Text('194', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('رقم الحوض', style: TextStyle(fontSize: 16))),
            DataCell(Text('14', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('اسم الحوض', style: TextStyle(fontSize: 16))),
            DataCell(Text('راس عيوش', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('اسم الحي', style: TextStyle(fontSize: 16))),
            DataCell(Text('خلة الشومر', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('رقم الحي', style: TextStyle(fontSize: 16))),
            DataCell(Text('3', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('السعر قبل التسوية', style: TextStyle(fontSize: 16))),
            DataCell(Text('20,000 دينار', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('السعر بعد التسوية', style: TextStyle(fontSize: 16))),
            DataCell(Text('18,000 دينار', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('للتواصل مع المالك', style: TextStyle(fontSize: 16))),
            DataCell(Text('0599-123456', style: TextStyle(fontSize: 16))),
          ]),
          DataRow(cells: <DataCell>[
            DataCell(Text('اسم المالك', style: TextStyle(fontSize: 16))),
            DataCell(Text('محمد مصطفى عبد الله بشارات',
                style: TextStyle(fontSize: 16))),
          ]),
        ],
      ),
    );
  }

  // Bidding Section
  Widget _buildBiddingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the map page
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              ),
              child: const Text('مشاهدة القطعة على الخريطة'),
            ),
            const SizedBox(width: 12),
            // ElevatedButton(
            //   onPressed: () {
            //     // Navigate to auction page or perform related action
            //   },
            //   style: ElevatedButton.styleFrom(
            //     padding:
            //         const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            //   ),
            //   child: const Text('مكان المزايدة'),
            // ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('أدخل سعرك للمنافسة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'ادخل السعر',
              hintStyle:
                  const TextStyle(fontSize: 10), // Smaller placeholder font
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Submit bid
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          ),
          child: const Text('المشاركة في المزاد'),
        ),
        const SizedBox(height: 16),

        // Bidding History
        const Text('المشاركين في المزاد:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Bidding Items with Dividers
        _buildBidItem('علي**129', '10,000 دينار', '15/2/2025 11:03'),
        Divider(color: Colors.grey[300], thickness: 1), // Light gray divider
        _buildBidItem('احمد**430', '9,500 دينار', '15/2/2025 10:50'),
        Divider(color: Colors.grey[300], thickness: 1), // Light gray divider
        _buildBidItem('894**محمد', '9,000 دينار', '14/2/2025 09:45'),
        Divider(color: Colors.grey[300], thickness: 1), // Light gray divider
        _buildBidItem('42**توفيق', '8,500 دينار', '14/2/2025 08:20'),
      ],
    );
  }

  // Bid Item Widget
  Widget _buildBidItem(String bidder, String amount, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(bidder, style: const TextStyle(fontSize: 14)),
          ),
          Text(amount, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 54),
          Text(time, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
