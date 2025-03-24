import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

// Enhanced Color Scheme
const primaryColor = Color(0xFF2D9CDB); // Blue
const secondaryColor = Color(0xFFFFA726); // Orange
const backgroundColor = Color(0xFFF8FAFC); // Light Gray
const cardColor = Colors.white;
const textColor = Color(0xFF2D3748); // Dark Gray
const accentColor = Color(0xFF48BB78); // Green
const shadowColor = Colors.black12;

class LandAuctionPage extends StatefulWidget {
  final List<Map<String, dynamic>> propertyData;

  const LandAuctionPage({
    Key? key,
    required this.propertyData,
  }) : super(key: key);

  @override
  _LandAuctionPageState createState() => _LandAuctionPageState();
}

class _LandAuctionPageState extends State<LandAuctionPage> {
  final _bidController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showFullHistory = false;
  bool _showFullDetails = false;
  Duration _timeRemaining = const Duration(hours: 24, minutes: 30);
  late Map<String, dynamic> property;
  late List<Bid> _bids;
  late AuctionDetails _auctionData;
  Timer? _timer;
  String? _userRole;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    property = widget.propertyData.first;
    _bids = [];
    _fetchBids(property['auctionDetails'][0]['landId']);
    _auctionData = AuctionDetails(
      landImages: (property['landsImagesUrls'] as List?)?.cast<String>() ?? [],
      description: property['description'] ?? '',
      currentBid: property['priceBefore']?.toDouble() ?? 0.0,
      startingPrice: property['priceBefore']?.toDouble() ?? 0.0,
      bids: _bids,
      ownerPhone: property['ownerPhone'] ?? '',
      coordinates: const LatLng(31.9539, 35.9106),
      endTime: property['auctionDetails'][0]['endAt'] != null
          ? DateTime.parse(property['auctionDetails'][0]['endAt'])
          : DateTime.now().add(const Duration(hours: 24, minutes: 30)),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeRemaining = _auctionData.endTime.difference(DateTime.now());
        });
      }
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] as String?;
          });
        }
      }).catchError((error) {
        print("Error fetching user role: $error");
      });
    }
  }

  void _fetchBids(String landId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('lands')
          .where('landId', isEqualTo: landId)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var landDoc = querySnapshot.docs.first;
        var bidsData = landDoc['bids'] as List<dynamic>? ?? [];
        setState(() {
          _bids = bidsData.map((bid) {
            return Bid(
              amount: (bid['amount'] as num?)?.toDouble() ?? 0.0,
              user: bid['user'] ?? '',
              time: DateTime.tryParse(bid['time'] ?? '') ?? DateTime.now(),
              auctionId: landId,
            );
          }).toList();
          _bids.sort((a, b) => b.amount.compareTo(a.amount));
          _auctionData = _auctionData.copyWith(bids: _bids);
        });
      }
    } catch (e) {
      print("Error fetching bids: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bidController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _placeBid(BuildContext context, TextEditingController bidController,
      Map<String, dynamic> property, List<Bid> bids, Function setState) async {
    FocusScope.of(context).unfocus();
    if (bidController.text.isEmpty) {
      _showSnackbar(context, 'يرجى إدخال قيمة المزايدة');
      return;
    }
    double bidAmount = double.tryParse(bidController.text) ?? 0.0;
    if (bidAmount <= 0) {
      _showSnackbar(context, 'قيمة المزايدة غير صحيحة');
      return;
    }
    String userId = property['traderId']?.toString() ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    String landId = (property['auctionDetails'] is List &&
            property['auctionDetails'].isNotEmpty)
        ? property['auctionDetails'][0]['landId']?.toString() ?? ''
        : '';
    if (landId.isEmpty) {
      _showSnackbar(context, 'خطأ: معرف الأرض غير موجود');
      return;
    }
    Bid newBid = Bid(
      amount: bidAmount,
      user: userId,
      time: DateTime.now(),
      auctionId: landId,
    );
    setState(() {
      bids.add(newBid);
      _auctionData = _auctionData.copyWith(currentBid: bidAmount);
    });
    String landDocAuctionId = await _getLandDocAuctionId(landId);
    if (landDocAuctionId.isEmpty) {
      _showSnackbar(context, 'خطأ: لم يتم العثور على الأرض بالمزاد');
      return;
    }
    try {
      DocumentReference landRef =
          FirebaseFirestore.instance.collection('lands').doc(landDocAuctionId);
      var docSnapshot = await landRef.get();
      if (!docSnapshot.exists ||
          (docSnapshot.data() != null &&
              !(docSnapshot.data() as Map<String, dynamic>)
                  .containsKey('bids'))) {
        await landRef.update({'bids': []});
      }
      await landRef.update({
        'bids': FieldValue.arrayUnion([newBid.toJson()]),
      });
      _showSnackbar(context, 'تمت المزايدة بنجاح');
      bidController.clear();
    } catch (e) {
      _showSnackbar(context, 'فشل في إرسال المزايدة: ${e.toString()}');
    }
  }

  Future<String> _getLandDocAuctionId(String auctionLandId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('lands')
          .where('landId', isEqualTo: auctionLandId)
          .get();
      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : '';
    } catch (e) {
      print('Error fetching land document: $e');
      return '';
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _viewFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(child: Image.network(imageUrl, fit: BoxFit.contain)),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: shadowColor,
        title: const Text(
          'مزاد الأرض',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              const SizedBox(height: 16),
              _buildTimerSection(),
              const SizedBox(height: 16),
              _buildDetailSection(),
              const SizedBox(height: 16),
              _buildBiddingForm(),
              if (_userRole != 'browserUser') ...[
                const SizedBox(height: 16),
                _buildCallOwnerButton(),
              ],
              const SizedBox(height: 16),
              _buildBidHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 250,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                onPageChanged: (index, reason) {
                  setState(() => _currentImageIndex = index);
                },
              ),
              items: _auctionData.landImages.isNotEmpty
                  ? _auctionData.landImages
                      .map((imageUrl) => Image.network(imageUrl,
                          fit: BoxFit.cover, width: double.infinity))
                      .toList()
                  : [
                      Image.network("https://via.placeholder.com/400",
                          fit: BoxFit.cover, width: double.infinity)
                    ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon:
                    const Icon(Icons.fullscreen, color: Colors.white, size: 28),
                onPressed: () => _viewFullScreenImage(
                  context,
                  _auctionData.landImages.isNotEmpty
                      ? _auctionData.landImages[_currentImageIndex]
                      : "https://via.placeholder.com/400",
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _auctionData.landImages
                    .map((url) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex ==
                                    _auctionData.landImages.indexOf(url)
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('أعلى مزايدة',
                  style: TextStyle(
                      fontSize: 14, color: textColor.withOpacity(0.7))),
              const SizedBox(height: 4),
              Text(
                'د.أ ${NumberFormat('#,##0').format(_auctionData.currentBid)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('الوقت المتبقي',
                  style: TextStyle(
                      fontSize: 14, color: textColor.withOpacity(0.7))),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: accentColor, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${_timeRemaining.inHours} س ${_timeRemaining.inMinutes.remainder(60)} د',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    List<Map<String, String>> detailRows = [
      {
        'title': 'مساحة الأرض',
        'value': property['landArea']?.toString() ?? 'غير محدد'
      },
      {'title': 'الموقع', 'value': property['location'] ?? 'غير محدد'},
      {'title': 'نوع الاستخدام', 'value': property['name'] ?? 'غير معروف'},
      {
        'title': 'السعر قبل التسوية',
        'value':
            'د.أ ${NumberFormat('#,##0').format(property['priceBefore'] ?? 0)}'
      },
      {
        'title': 'السعر بعد التسوية',
        'value':
            'د.أ ${NumberFormat('#,##0').format(property['priceAfter'] ?? 0)}'
      },
      {
        'title': 'السعر لكل متر قبل',
        'value':
            'د.أ ${NumberFormat('#,##0.00').format(property['pricePerMeterBefore'] ?? 0)}'
      },
      {
        'title': 'السعر لكل متر بعد',
        'value':
            'د.أ ${NumberFormat('#,##0.00').format(property['pricePerMeterAfter'] ?? 0)}'
      },
      {
        'title': 'رقم الحوض',
        'value': property['basinNumber']?.toString() ?? 'غير متوفر'
      },
      {
        'title': 'رقم الحي',
        'value': property['neighborhoodNumber']?.toString() ?? 'غير متوفر'
      },
      {
        'title': 'رقم القطعة',
        'value': property['plotNumber']?.toString() ?? 'غير متوفر'
      },
      {'title': 'الحي', 'value': property['neighborhood'] ?? 'غير متوفر'},
      {'title': 'رقم الهاتف', 'value': property['phone'] ?? 'غير متوفر'},
      if (_userRole != 'browserUser') ...[
        {
          'title': 'رقم هاتف المالك',
          'value': property['ownerPhone'] ?? 'غير متوفر'
        },
        {'title': 'اسم المالك', 'value': property['ownerName'] ?? 'غير متوفر'},
      ],
    ];
    final rowsToShow =
        _showFullDetails ? detailRows : detailRows.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل العقار',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
            children: rowsToShow
                .map((row) => _buildTableRow(row['title']!, row['value']!))
                .toList(),
          ),
          if (detailRows.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _showFullDetails = !_showFullDetails),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showFullDetails ? 'عرض أقل' : 'عرض المزيد',
                      style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                        _showFullDetails
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: primaryColor,
                        size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(value,
              style: const TextStyle(fontSize: 14, color: textColor)),
        ),
      ],
    );
  }

  Widget _buildBiddingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('قدم مزايدتك',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'د.أ ',
                    hintText: 'أدخل المبلغ',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14, color: textColor),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _placeBid(
                    context, _bidController, property, _bids, setState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('مزايدة',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallOwnerButton() {
    return ElevatedButton.icon(
      onPressed: () => _callOwner(property['ownerPhone']),
      icon: const Icon(Icons.phone, size: 20),
      label: const Text('اتصل بالمالك',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  Widget _buildBidHistory() {
    final bidsToShow =
        _showFullHistory ? _auctionData.bids : _auctionData.bids.take(3);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: shadowColor, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('سجل المزايدات',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
              if (_auctionData.bids.length > 3)
                TextButton(
                  onPressed: () =>
                      setState(() => _showFullHistory = !_showFullHistory),
                  child: Text(
                    _showFullHistory ? 'عرض أقل' : 'عرض المزيد',
                    style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (bidsToShow.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('لا توجد مزايدات بعد',
                  style: TextStyle(
                      color: textColor.withOpacity(0.6), fontSize: 14)),
            )
          else
            ...bidsToShow.map((bid) => _buildBidItem(bid)).toList(),
        ],
      ),
    );
  }

  Widget _buildBidItem(Bid bid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = currentUser != null && bid.user == currentUser.uid;
    final displayText = isCurrentUser
        ? (currentUser.displayName ?? 'أنت')
        : (bid.user.length > 10
            ? bid.user.substring(bid.user.length - 10)
            : bid.user);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayText,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor)),
              Text(
                DateFormat('dd MMM, yyyy - HH:mm').format(bid.time),
                style:
                    TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
              ),
            ],
          ),
          Text(
            'د.أ ${NumberFormat('#,##0').format(bid.amount)}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
          ),
        ],
      ),
    );
  }

  Future<void> _callOwner(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showSnackbar(context, 'لا يمكن إجراء المكالمة');
    }
  }
}

class AuctionDetails {
  final List<String> landImages;
  final String description;
  final double currentBid;
  final double startingPrice;
  final List<Bid> bids;
  final String ownerPhone;
  final LatLng coordinates;
  final DateTime endTime;

  AuctionDetails({
    required this.landImages,
    required this.description,
    required this.currentBid,
    required this.startingPrice,
    required this.bids,
    required this.ownerPhone,
    required this.coordinates,
    required this.endTime,
  });

  AuctionDetails copyWith({
    List<String>? landImages,
    String? description,
    double? currentBid,
    double? startingPrice,
    List<Bid>? bids,
    String? ownerPhone,
    LatLng? coordinates,
    DateTime? endTime,
  }) {
    return AuctionDetails(
      landImages: landImages ?? this.landImages,
      description: description ?? this.description,
      currentBid: currentBid ?? this.currentBid,
      startingPrice: startingPrice ?? this.startingPrice,
      bids: bids ?? this.bids,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      coordinates: coordinates ?? this.coordinates,
      endTime: endTime ?? this.endTime,
    );
  }
}

class Bid {
  final double amount;
  final String user;
  final DateTime time;
  final String auctionId;

  Bid({
    required this.amount,
    required this.user,
    required this.time,
    required this.auctionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'user': user,
      'time': time.toIso8601String(),
      'auctionId': auctionId,
    };
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class UpgradeToTraderPage extends StatelessWidget {
  const UpgradeToTraderPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ترقية إلى تاجر'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        color: backgroundColor,
        child: const Center(
          child: Text(
            'صفحة لترقية الحساب إلى تاجر - يتم التنفيذ لاحقًا',
            style: TextStyle(fontSize: 18, color: textColor),
          ),
        ),
      ),
    );
  }
}
