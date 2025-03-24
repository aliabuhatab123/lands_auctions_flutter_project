import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:gis/Screens/Add_Property/add_prop_page_b.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  // Controllers for basic info
  final TextEditingController priceController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController beforeSettlementController =
      TextEditingController();
  final TextEditingController afterSettlementController =
      TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Controllers for new fields
  final TextEditingController pricePerMeterBeforeController =
      TextEditingController();
  final TextEditingController pricePerMeterAfterController =
      TextEditingController();
  final TextEditingController plotNumberController = TextEditingController();
  final TextEditingController basinNumberController = TextEditingController();
  final TextEditingController neighborhoodNumberController =
      TextEditingController();
  final TextEditingController coordinateXController = TextEditingController();
  final TextEditingController coordinateYController = TextEditingController();

  // Owner info controllers
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerIdController = TextEditingController();
  final TextEditingController ownerPhoneController = TextEditingController();
  final TextEditingController ownerEmailController = TextEditingController();

  // Dropdown values
  String? selectedCity = 'ترمسعيا';
  String? selectedNeighborhood = 'المسارب';
  String? selectedPropertyType = 'للاستثمار السكني';

  // Helper method to store input values as JSON
  Map<String, dynamic> _getFormData() {
    return {
      // Basic information
      'location': selectedCity,
      'neighborhood': selectedNeighborhood,
      'traderId': '67ad2052e4b8607f47e84cb7',
      'name': selectedPropertyType,
      'description': descriptionController.text,

      // Land details
      'landArea': double.tryParse(areaController.text) ?? 0.0,
      'plotNumber': plotNumberController.text,
      'basinNumber': basinNumberController.text,
      'neighborhoodNumber': neighborhoodNumberController.text,

      // Price information
      'price': double.tryParse(priceController.text) ?? 0.0,
      'priceBefore': double.tryParse(beforeSettlementController.text) ?? 0.0,
      'priceAfter': double.tryParse(afterSettlementController.text) ?? 0.0,
      'pricePerMeterBefore':
          double.tryParse(pricePerMeterBeforeController.text) ?? 0.0,
      'pricePerMeterAfter':
          double.tryParse(pricePerMeterAfterController.text) ?? 0.0,

      // Coordinates
      'coordinates': {
        'x': double.tryParse(coordinateXController.text) ?? 0.0,
        'y': double.tryParse(coordinateYController.text) ?? 0.0,
      },

      // Owner information
      'ownerName': ownerNameController.text,
      'ownerPhone': ownerPhoneController.text,
      'ownerEmail': ownerEmailController.text,
      'ownerId': ownerIdController.text,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إضافة عقار',
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('معلومات الموقع'),
                _buildLocationSection(),
                _buildSectionTitle('معلومات القطعة'),
                _buildPlotSection(),
                _buildSectionTitle('الأسعار'),
                _buildPriceSection(),
                _buildSectionTitle('الإحداثيات'),
                _buildCoordinatesSection(),
                _buildSectionTitle('معلومات المالك'),
                _buildOwnerSection(),
                SizedBox(height: 24),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                value: selectedCity,
                items: ['ترمسعيا', 'طمون'],
                label: 'المدينة',
                onChanged: (value) => setState(() => selectedCity = value),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildDropdownField(
                value: selectedNeighborhood,
                items: [
                  "المسارب",
                  "الشمالي الغربي",
                  "الشمالي الشرقي",
                  "الوسط",
                  "الجنوبي الغربي",
                  "الجنوبي",
                  "الشرقي",
                  "الجنوبي الشرقي",
                  "الوسط الاول",
                  "الغربي",
                  "الوسط الثاني",
                  "الشرقي الجنوبي",
                  "الشهيد زياد ابو عين",
                  "ابو فاضل الشمالي",
                  "ابو فاضل الجنوبي",
                  "تحت العراق الشرقي",
                  "خربة كفر سطونه",
                  "عراق النمر",
                  "حبول ذياب",
                  "تحت العراق الغربي",
                  "تحت العراق الوسط",
                  "الدبات الجنوبي",
                  "الدبات الشمالي",
                  "الكركعة",
                  "شعب البوريني",
                  "الزقايق",
                  "المساطيح",
                  "شعب الطاقه",
                  "الشمالي",
                  "معشر",
                  "الطف",
                  "البيوض الجنوبي",
                  "الحنية الشمالية",
                  "البيوض الشمالي",
                  "البركة",
                  "راس دار جبارة",
                  "الحواري",
                  "تحت الزاوية",
                  "الحنية الجنوبية",
                  "الشونة الشرقية",
                  "الشونة الغربية",
                  "وادي الحمام",
                  "القرنة",
                  "المسارب",
                  "جروفة",
                  "خلة البلد",
                  "ابو الحولزان",
                  "ابو النتش",
                  "صدر الثعلا",
                  "خلة نصره",
                  "عراق نصره",
                  "بلام الضيف",
                  "صر المكسر",
                  "جوزة خير الله",
                  "حلة ابو سالم",
                  "طاحونة التوم",
                  "العتماوية",
                  "راس بلام الضيف",
                  "عراق العجلة",
                  "تل ابو رمح",
                  "مطلع المكسر",
                  "مرجان سارة",
                  "جورة داوود",
                  "وادي الضبع",
                  "خلة الحرذون",
                  "واد الاشقر",
                  "جورة النقب",
                  "واد السمكة",
                  "خلة حرذون",
                  "صدر السمكة",
                  "الغربي الثاني",
                  "الشرقي الاول",
                  "قرطات السمكة",
                  "خلة الطيور",
                  "دباب الهوش الغربي",
                  "دباب الهوش الشرقي",
                  "قرطات دباب الهوش",
                  "الطاهر",
                  "شويحط الشمالي",
                  "الشرقي الثاني",
                  "المعيار الشمالي",
                  "البستان",
                  "القصر",
                  "المعيار الجنوبي",
                  "شويحط الجنوبي",
                  "البعجاوي",
                  "ام الكبيش الجنوبي",
                  "خربة الصفيره",
                  "وادي الاسقر",
                  "خلة الشومر",
                  "خلة الجمال",
                  "عراق السحيلة",
                  "دباب الدولة",
                  "الصفيره الشمالية",
                  "سدرة ام الشراميح",
                  "خلة حسن التحتا",
                  "خلة الحمام الجنوبي"
                ],
                label: 'الحي',
                onChanged: (value) =>
                    setState(() => selectedNeighborhood = value),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPlotSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: plotNumberController,
                label: 'رقم القطعة',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: basinNumberController,
                label: 'رقم الحوض',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: neighborhoodNumberController,
                label: 'رقم الحي',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: areaController,
                label: 'المساحة (متر مربع)',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildDropdownField(
          value: selectedPropertyType,
          items: ['للاستثمار الزراعي', 'للاستثمار العقاري', 'للبناء السكني'],
          label: 'نوع العقار',
          onChanged: (value) => setState(() => selectedPropertyType = value),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: pricePerMeterBeforeController,
                label: 'سعر المتر قبل التسوية',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: pricePerMeterAfterController,
                label: 'سعر المتر بعد التسوية',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: beforeSettlementController,
                label: 'السعر قبل التسوية',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: afterSettlementController,
                label: 'السعر بعد التسوية',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildTextField(
          controller: priceController,
          label: 'سعر المزاد الابتدائي',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildCoordinatesSection() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: coordinateXController,
            label: 'X إحداثي',
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: coordinateYController,
            label: 'Y إحداثي',
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerSection() {
    return Column(
      children: [
        _buildTextField(
          controller: ownerNameController,
          label: 'اسم المالك',
        ),
        SizedBox(height: 12),
        _buildTextField(
          controller: ownerIdController,
          label: 'رقم الهوية',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 12),
        _buildTextField(
          controller: ownerPhoneController,
          label: 'رقم الهاتف',
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 12),
        _buildTextField(
          controller: ownerEmailController,
          label: 'البريد الإلكتروني',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final formData = _getFormData();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IdVerificationScreen(formData: formData),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'التالي',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
