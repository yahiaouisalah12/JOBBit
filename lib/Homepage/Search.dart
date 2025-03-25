import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "الكل";
  final List<String> _categories = [
    "الكل",
    "تطوير الويب",
    "تطوير الموبايل",
    "تصميم UI/UX",
    "تسويق رقمي",
    "إدارة مشاريع"
  ];

  final List<String> _recentSearches = [
    "مطور فلاتر",
    "مصمم واجهات",
    "مطور ويب",
    "مسوق إلكتروني"
  ];

  final List<Map<String, dynamic>> _popularJobs = [
    {
      "title": "مطور واجهة أمامية",
      "company": "شركة تكنولوجيا",
      "location": "الجزائر، ورقلة",
      "salary": "100000 دج/شهر",
      "type": "دوام كامل",
      "logo": "FE"
    },
    {
      "title": "مصمم UI/UX",
      "company": "استوديو تصميم",
      "location": "الجزائر، العاصمة",
      "salary": "120000 دج/شهر",
      "type": "عن بعد",
      "logo": "UI"
    },
    {
      "title": "مطور تطبيقات موبايل",
      "company": "شركة برمجيات",
      "location": "الجزائر، وهران",
      "salary": "110000 دج/شهر",
      "type": "دوام كامل",
      "logo": "MD"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: const Text(
          "البحث عن وظائف",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "ابحث عن وظيفة، شركة، أو مهارة...",
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF8A70D6)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.filter_list,
                          color: Color(0xFF36305E)),
                      onPressed: () {
                        _showFilterBottomSheet(context);
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onSubmitted: (value) {
                    // تنفيذ البحث
                  },
                ),
              ),

              const SizedBox(height: 25),

              // Categories
              const Text(
                "التصنيفات",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF36305E),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryChip(_categories[index]);
                  },
                ),
              ),

              const SizedBox(height: 25),

              // Recent searches
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "عمليات البحث الأخيرة",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF36305E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _recentSearches.clear();
                      });
                    },
                    child: const Text(
                      "مسح الكل",
                      style: TextStyle(
                        color: Color(0xFF8A70D6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _recentSearches.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "لا توجد عمليات بحث سابقة",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: _recentSearches.map((search) {
                        return _buildRecentSearchItem(search);
                      }).toList(),
                    ),

              const SizedBox(height: 25),

              // Popular jobs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "الوظائف الشائعة",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF36305E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // عرض المزيد من الوظائف
                    },
                    child: const Text(
                      "عرض الكل",
                      style: TextStyle(
                        color: Color(0xFF8A70D6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Column(
                children: _popularJobs.map((job) {
                  return _buildJobCard(job);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لإنشاء شريحة تصنيف
  Widget _buildCategoryChip(String category) {
    bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8A70D6) : const Color(0xFFEFEBFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF36305E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // دالة لإنشاء عنصر بحث سابق
  Widget _buildRecentSearchItem(String search) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history,
            color: Color(0xFF8A70D6),
            size: 20,
          ),
          const SizedBox(width: 15),
          Text(
            search,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.north_west,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () {
              _searchController.text = search;
            },
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء بطاقة وظيفة
  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF36305E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    job["logo"],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job["title"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF36305E),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      job["company"],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border,
                  color: Color(0xFF8A70D6),
                ),
                onPressed: () {
                  // حفظ الوظيفة
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildJobFeature(Icons.location_on, job["location"]),
              const SizedBox(width: 15),
              _buildJobFeature(Icons.attach_money, job["salary"]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildJobTypeChip(job["type"]),
              TextButton(
                onPressed: () {
                  // عرض تفاصيل الوظيفة
                },
                child: const Text(
                  "عرض التفاصيل",
                  style: TextStyle(
                    color: Color(0xFF8A70D6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء ميزة وظيفة
  Widget _buildJobFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF8A70D6),
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // دالة لإنشاء شريحة نوع الوظيفة
  Widget _buildJobTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEBFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Color(0xFF8A70D6),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // دالة لعرض نافذة الفلترة
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تصفية النتائج",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF36305E),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _buildFilterSection(
                      "نوع الوظيفة",
                      ["دوام كامل", "دوام جزئي", "عن بعد", "عقد مؤقت"],
                    ),
                    _buildFilterSection(
                      "المستوى الوظيفي",
                      ["مبتدئ", "متوسط", "خبير", "مدير"],
                    ),
                    _buildFilterSection(
                      "الراتب",
                      [
                        "أقل من 50000 دج",
                        "50000 - 100000 دج",
                        "100000 - 150000 دج",
                        "أكثر من 150000 دج"
                      ],
                    ),
                    _buildFilterSection(
                      "الموقع",
                      ["الجزائر العاصمة", "وهران", "قسنطينة", "ورقلة", "عنابة"],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // إعادة تعيين الفلاتر
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Color(0xFF8A70D6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "إعادة تعيين",
                        style: TextStyle(
                          color: Color(0xFF8A70D6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // تطبيق الفلاتر
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF36305E),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "تطبيق",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // دالة لإنشاء قسم فلترة
  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF36305E),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: false,
              onSelected: (selected) {
                // تحديد الخيار
              },
              backgroundColor: const Color(0xFFEFEBFF),
              selectedColor: const Color(0xFF8A70D6),
              checkmarkColor: Colors.white,
              labelStyle: const TextStyle(
                color: Color(0xFF36305E),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }
}
