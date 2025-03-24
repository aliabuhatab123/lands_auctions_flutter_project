import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final Set<String> selectedTags = {};
  final Map<String, String> selectedFilters = {};

  final List<String> suggestedTags = [
    "حبول ذياب",
    "المساطيح",
  ];
  final List<String> cityOptions = ["المدينة 1", "المدينة 2", "المدينة 3"];
  final List<String> neighborhoodOptions = ["اسم الحي 1", "اسم الحي 2"];
  final List<String> plotNumbers = ["رقم الحوض 1", "رقم الحوض 2"];
  final List<String> landNumbers = ["رقم القطعة 1", "رقم القطعة 2"];

  void toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  void submitSearch() {
    final searchCriteria = {
      'tags': selectedTags.toList(),
      ...selectedFilters,
    };

    print('Search Criteria: $searchCriteria');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Set the background color of the page to white
      appBar: AppBar(
        title: const Text(
          "البحث",
          style: TextStyle(fontFamily: "IBM_Bold"),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              "ابحث عن قطعة الارض التي تناسبك",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "IBM_Bold",
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "كلمات بحث مقترحة",
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: "IBM_Bold",
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestedTags.map((tag) {
                  return GestureDetector(
                    onTap: () => toggleTag(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selectedTags.contains(tag)
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                            color: selectedTags.contains(tag)
                                ? Colors.blue
                                : Colors.grey[300]!),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: selectedTags.contains(tag)
                              ? Colors.blue
                              : Colors.black,
                          fontFamily: "IBM_Regular",
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "المعلومات الاساسية",
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: "IBM_Bold",
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: buildDropdownField(
                              "المدينة", cityOptions, "city")),
                      const SizedBox(width: 8),
                      Expanded(
                          child: buildDropdownField(
                              "اسم الحي", neighborhoodOptions, "neighborhood")),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: buildDropdownField(
                              "رقم الحوض", plotNumbers, "plotNumber")),
                      const SizedBox(width: 8),
                      Expanded(
                          child: buildDropdownField(
                              "رقم القطعة", landNumbers, "landNumber")),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "فلترة",
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: "IBM_Bold",
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  "متاحة",
                  "محجوزة",
                  "مباعة",
                  "10-15 الف",
                  "15-20 الف",
                  "اكثر من 20 الف",
                  "اقل من 10 الاف",
                  "تصلح للبناء",
                  "مستوية",
                  "انحدار طفيف",
                  "ارض زراعية",
                  "منحدرة",
                ].map((filter) {
                  return GestureDetector(
                    onTap: () => toggleTag(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selectedTags.contains(filter)
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                            color: selectedTags.contains(filter)
                                ? Colors.blue
                                : Colors.grey[300]!),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: selectedTags.contains(filter)
                              ? Colors.blue
                              : Colors.black,
                          fontFamily: "IBM_Regular",
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.black, // Set the button background color to black
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "ابحث",
                style: TextStyle(
                  fontFamily: "IBM_Bold",
                  fontSize: 16,
                  color: Colors.white, // Set the button text color to white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdownField(String label, List<String> options, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: "IBM_Regular",
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(fontFamily: "IBM_Regular"),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedFilters[key] = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
