import 'package:flutter/material.dart';
import 'package:memoire/AddJob/AddJob.dart';

class Honecompane extends StatefulWidget {
  const Honecompane({super.key});

  @override
  State<Honecompane> createState() => _HonecompaneState();
}

class _HonecompaneState extends State<Honecompane>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  // بيانات الشركة
  final Map<String, dynamic> _companyData = {
    "name": "شركة تكنولوجيا المعلومات",
    "logo": "TI",
    "industry": "تكنولوجيا المعلومات",
    "location": "الجزائر، العاصمة",
    "employees": "50-200 موظف",
    "founded": "2015",
    "website": "www.techinfo.dz",
    "description":
        "شركة رائدة في مجال تطوير البرمجيات وتقديم حلول تكنولوجية متكاملة للشركات والمؤسسات في الجزائر والعالم العربي.",
  };

  // بيانات الوظائف المنشورة
  final List _postedJobs = [
    {
      "id": 1,
      "title": "مطور واجهة أمامية",
      "type": "دوام كامل",
      "location": "الرياض",
      "salary": "15000 - 20000 ريال",
      "posted": "منذ 3 أيام",
      "applicants": 12,
      "status": "نشط",
    },
    {
      "id": 2,
      "title": "مصمم UX/UI",
      "type": "دوام جزئي",
      "location": "جدة",
      "salary": "10000 - 15000 ريال",
      "posted": "منذ 5 أيام",
      "applicants": 8,
      "status": "نشط",
    },
    {
      "id": 3,
      "title": "مطور تطبيقات موبايل",
      "type": "عن بعد",
      "location": "أي مكان",
      "salary": "20000 - 25000 ريال",
      "posted": "منذ أسبوع",
      "applicants": 20,
      "status": "مغلق",
    },
  ];

  // بيانات المتقدمين
  final List<Map<String, dynamic>> _applicants = [
    {
      "id": "APP001",
      "name": "أحمد محمد",
      "position": "مطور واجهة أمامية",
      "experience": "3 سنوات",
      "education": "بكالوريوس علوم الحاسوب",
      "status": "قيد المراجعة",
      "applied": "منذ يومين",
      "avatar": "AM",
    },
    {
      "id": "APP002",
      "name": "سارة علي",
      "position": "مصمم واجهات المستخدم",
      "experience": "4 سنوات",
      "education": "بكالوريوس تصميم جرافيك",
      "status": "تمت المقابلة",
      "applied": "منذ 5 أيام",
      "avatar": "SA",
    },
    {
      "id": "APP003",
      "name": "محمود خالد",
      "position": "مطور تطبيقات موبايل",
      "experience": "2 سنوات",
      "education": "ماجستير هندسة البرمجيات",
      "status": "مقبول",
      "applied": "منذ أسبوع",
      "avatar": "MK",
    },
    {
      "id": "APP004",
      "name": "ليلى عمر",
      "position": "مطور واجهة أمامية",
      "experience": "1 سنة",
      "education": "بكالوريوس علوم الحاسوب",
      "status": "مرفوض",
      "applied": "منذ أسبوعين",
      "avatar": "LO",
    },
  ];

  // بيانات الإحصائيات
  final List<Map<String, dynamic>> _statistics = [
    {
      "title": "الوظائف النشطة",
      "value": "3",
      "icon": Icons.work,
      "color": Colors.blue,
    },
    {
      "title": "المتقدمين الجدد",
      "value": "15",
      "icon": Icons.people,
      "color": Colors.green,
    },
    {
      "title": "المقابلات",
      "value": "5",
      "icon": Icons.calendar_today,
      "color": Colors.orange,
    },
    {
      "title": "معدل القبول",
      "value": "25%",
      "icon": Icons.check_circle,
      "color": Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isMediumScreen =
        screenSize.width >= 600 && screenSize.width < 900;
    final bool isLargeScreen = screenSize.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: Text(
          "لوحة تحكم الشركة",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            // تعديل حجم النص حسب حجم الشاشة
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ملخص الشركة
          _buildCompanySummary(isSmallScreen, isMediumScreen),

          // علامات التبويب
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF36305E),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF8A70D6),
              labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              tabs: const [
                Tab(text: "الوظائف", icon: Icon(Icons.work, size: 24)),
                Tab(text: "المتقدمين", icon: Icon(Icons.people, size: 24)),
                Tab(text: "الإحصائيات", icon: Icon(Icons.analytics, size: 24)),
              ],
            ),
          ),

          // محتوى علامات التبويب
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // علامة تبويب الوظائف
                _buildJobsTab(isSmallScreen, isMediumScreen, isLargeScreen),

                // علامة تبويب المتقدمين
                _buildApplicantsTab(
                    isSmallScreen, isMediumScreen, isLargeScreen),

                // علامة تبويب الإحصائيات
                _buildStatisticsTab(
                    isSmallScreen, isMediumScreen, isLargeScreen),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF36305E),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => Addjob(
                          companyID: 1,
                        )));
              },
            )
          : null,
    );
  }

  // بناء ملخص الشركة
  Widget _buildCompanySummary(bool isSmallScreen, bool isMediumScreen) {
    if (isSmallScreen) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF36305E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8A70D6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  _companyData["logo"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _companyData["name"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.business,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _companyData["industry"],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _companyData["location"],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(isMediumScreen ? 15 : 20),
        color: const Color(0xFF36305E),
        child: Row(
          children: [
            Container(
              width: isMediumScreen ? 60 : 80,
              height: isMediumScreen ? 60 : 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8A70D6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  _companyData["logo"],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMediumScreen ? 20 : 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _companyData["name"],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMediumScreen ? 16 : 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.business,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _companyData["industry"],
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isMediumScreen ? 12 : 14,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _companyData["location"],
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isMediumScreen ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _companyData["description"],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMediumScreen ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
              onPressed: () {
                // تعديل ملف الشركة
              },
            ),
          ],
        ),
      );
    }
  }

  // بناء علامة تبويب الوظائف
  Widget _buildJobsTab(
    bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    if (_postedJobs.isEmpty) {
      return _buildEmptyState(
        "No jobs posted",
        "Click the add button to post a new job",
        Icons.work_off,
        isSmallScreen,
      );
    }

    if (isLargeScreen) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _postedJobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(_postedJobs[index], isSmallScreen);
        },
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
        itemCount: _postedJobs.length,
        itemBuilder: (context, index) {
          return _buildJobCard(_postedJobs[index], isSmallScreen);
        },
      );
    }
  }

  // بناء علامة تبويب المتقدمين
  Widget _buildApplicantsTab(
      bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    if (_applicants.isEmpty) {
      return _buildEmptyState(
        "لا يوجد متقدمين",
        "سيظهر هنا المتقدمين للوظائف المنشورة",
        Icons.people_outline,
        isSmallScreen,
      );
    }

    if (isLargeScreen) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _applicants.length,
        itemBuilder: (context, index) {
          return _buildApplicantCard(_applicants[index], isSmallScreen);
        },
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
        itemCount: _applicants.length,
        itemBuilder: (context, index) {
          return _buildApplicantCard(_applicants[index], isSmallScreen);
        },
      );
    }
  }

  // بناء علامة تبويب الإحصائيات
  Widget _buildStatisticsTab(
      bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقات الإحصائيات
          SizedBox(
            height: isSmallScreen ? 140 : 170,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isLargeScreen ? 4 : (isMediumScreen ? 3 : 2),
              crossAxisSpacing: isSmallScreen ? 8 : 12,
              mainAxisSpacing: isSmallScreen ? 8 : 12,
              childAspectRatio: isSmallScreen ? 1.3 : 1.6,
              children: _statistics.map((stat) {
                return _buildStatCard(stat, isSmallScreen);
              }).toList(),
            ),
          ),

          const SizedBox(height: 30),

          // رسم بياني للمتقدمين (تمثيل بسيط)
          const Text(
            "نشاط المتقدمين",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF36305E),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 200,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: isSmallScreen
                  ? [
                      _buildChartBar(
                          "الإثنين", 0.5, Colors.blue, isSmallScreen),
                      _buildChartBar(
                          "الثلاثاء", 0.7, Colors.blue, isSmallScreen),
                      _buildChartBar(
                          "الأربعاء", 0.4, Colors.blue, isSmallScreen),
                      _buildChartBar("الخميس", 0.6, Colors.blue, isSmallScreen),
                    ]
                  : [
                      _buildChartBar("الأحد", 0.3, Colors.blue, isSmallScreen),
                      _buildChartBar(
                          "الإثنين", 0.5, Colors.blue, isSmallScreen),
                      _buildChartBar(
                          "الثلاثاء", 0.7, Colors.blue, isSmallScreen),
                      _buildChartBar(
                          "الأربعاء", 0.4, Colors.blue, isSmallScreen),
                      _buildChartBar("الخميس", 0.6, Colors.blue, isSmallScreen),
                      _buildChartBar("الجمعة", 0.2, Colors.blue, isSmallScreen),
                      _buildChartBar("السبت", 0.1, Colors.blue, isSmallScreen),
                    ],
            ),
          ),

          const SizedBox(height: 30),

          // توزيع حالات المتقدمين
          const Text(
            "حالات المتقدمين",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF36305E),
            ),
          ),
          const SizedBox(height: 15),
          Container(
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
              children: [
                _buildStatusBar(
                    "قيد المراجعة", 0.4, Colors.orange, isSmallScreen),
                const SizedBox(height: 15),
                _buildStatusBar(
                    "تمت المقابلة", 0.3, Colors.blue, isSmallScreen),
                const SizedBox(height: 15),
                _buildStatusBar("مقبول", 0.2, Colors.green, isSmallScreen),
                const SizedBox(height: 15),
                _buildStatusBar("مرفوض", 0.1, Colors.red, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة وظيفة
  Widget _buildJobCard(Map<String, dynamic> job, bool isSmallScreen) {
    final bool isActive = job["status"] == "نشط";

    return Container(
      height: 220,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
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
          // Header
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF36305E) : Colors.grey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job["title"],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: isSmallScreen ? 3 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job["type"],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job details
                Wrap(
                  spacing: 15,
                  runSpacing: 5,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.work_history,
                          color: Colors.grey,
                          size: isSmallScreen ? 14 : 16,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "Experience: ${job["experience"]} years",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description,
                          color: Colors.grey,
                          size: isSmallScreen ? 14 : 16,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "Description available",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Additional info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Posted: ${job["posted"]}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                    ),
                    Text(
                      "Skills: ${job["skils"]?.length ?? 0}",
                      style: TextStyle(
                        color: const Color(0xFF8A70D6),
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.edit, size: isSmallScreen ? 16 : 20),
                        label: Text(
                          "Edit",
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        ),
                        onPressed: () {
                          // Edit job
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => Addjob(
                              companyID: 1,
                              // You can pass job data here for editing
                            ),
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF36305E),
                          side: const BorderSide(color: Color(0xFF36305E)),
                          padding: isSmallScreen
                              ? const EdgeInsets.symmetric(vertical: 8)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isActive ? Icons.visibility : Icons.visibility_off,
                          size: isSmallScreen ? 16 : 20,
                        ),
                        label: Text(
                          isActive ? "Hide" : "Publish",
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        ),
                        onPressed: () {
                          // Change job status
                          setState(() {
                            job["status"] = isActive ? "مغلق" : "نشط";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isActive ? Colors.red : const Color(0xFF36305E),
                          foregroundColor: Colors.white,
                          padding: isSmallScreen
                              ? const EdgeInsets.symmetric(vertical: 8)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة متقدم
  Widget _buildApplicantCard(
      Map<String, dynamic> applicant, bool isSmallScreen) {
    Color statusColor;
    switch (applicant["status"]) {
      case "قيد المراجعة":
        statusColor = Colors.orange;
        break;
      case "تمت المقابلة":
        statusColor = Colors.blue;
        break;
      case "مقبول":
        statusColor = Colors.green;
        break;
      case "مرفوض":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      height: isSmallScreen ? 90 : 100,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
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
      child: InkWell(
        onTap: () {
          // _showApplicantDetailsDialog(applicant);
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
          child: Row(
            children: [
              // صورة المتقدم
              Container(
                width: isSmallScreen ? 50 : 60,
                height: isSmallScreen ? 50 : 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF8A70D6),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
                ),
                child: Center(
                  child: Text(
                    applicant["avatar"],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 20,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 15),
              // معلومات المتقدم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      applicant["name"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                        color: const Color(0xFF36305E),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 3 : 5),
                    Text(
                      applicant["position"],
                      style: TextStyle(
                        color: const Color(0xFF8A70D6),
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 3 : 5),
                    // معلومات إضافية - متجاوبة للشاشات الصغيرة
                    isSmallScreen
                        ? Row(
                            children: [
                              const Icon(
                                Icons.work,
                                color: Colors.grey,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "الخبرة: ${applicant["experience"]}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.grey,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "تقدم: ${applicant["applied"]}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.work,
                                color: Colors.grey,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "الخبرة: ${applicant["experience"]}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.grey,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "تقدم: ${applicant["applied"]}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              // حالة المتقدم
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  applicant["status"],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء بطاقة إحصائية
  Widget _buildStatCard(Map<String, dynamic> stat, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisSize: MainAxisSize.min, // تحديد الحجم الأدنى للعمود
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat["color"].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              stat["icon"],
              color: stat["color"],
              size: isSmallScreen ? 20 : 25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat["value"],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 20,
              color: const Color(0xFF36305E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat["title"],
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  // بناء عمود رسم بياني
  Widget _buildChartBar(
      String label, double value, Color color, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 150 * value,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isSmallScreen ? 10 : 12,
          ),
        ),
      ],
    );
  }

  // بناء شريط حالة
  Widget _buildStatusBar(
      String label, double value, Color color, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(10),
          minHeight: 8,
        ),
      ],
    );
  }

  // بناء حالة فارغة
  Widget _buildEmptyState(
      String title, String subtitle, IconData icon, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 80 : 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
