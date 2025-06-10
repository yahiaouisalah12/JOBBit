import 'dart:async';
import 'dart:io'; // لإضافة SocketException
import 'package:flutter/material.dart';
import 'package:memoire/AddJob/AddJob.dart';
import 'package:memoire/Servers/api_servers.dart';
import 'package:memoire/Compane/RequestID.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Honecompane extends StatefulWidget {
  final int? companyID; // إضافة معامل companyID اختياري

  const Honecompane({super.key, this.companyID});

  @override
  State<Honecompane> createState() => _HonecompaneState();
}

class _HonecompaneState extends State<Honecompane>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  List _postedJobs = [];
  List _applicants = [];
  int companyID = 0;

  // --- StreamController for Jobs ---
  late StreamController<List<dynamic>> _jobsStreamController;
  Stream<List<dynamic>> get jobsStream => _jobsStreamController.stream;
  // قائمة لتخزين الوظائف الحالية
  List<dynamic> _currentJobs = [];
  // --- End StreamController ---

  // --- StreamController for Applicants ---
  late StreamController<List<dynamic>> _applicantsStreamController;
  Stream<List<dynamic>> get applicantsStream =>
      _applicantsStreamController.stream;
  // --- End StreamController for Applicants ---

  // بيانات الشركة المؤقتة (للعرض قبل التحميل)
  final Map<String, dynamic> _placeholderCompanyData = {
    "name": "Loading...",
    // logoPath will be handled in build
    "wilayaInfo": {"name": "-"}, // Placeholder for location
    "description": "Loading company description...",
    "link": "-",
    "email": "-",
    "phone": "-",
  };

  // بيانات الشركة الفعلية التي تم جلبها من API
  Map<String, dynamic>? _fetchedCompanyData;

  // بيانات الشركة
  final Map<String, dynamic> _companyData = {
    "name": "Information Technology Company",
    "logo": "TI",
    "industry": "Information Technology",
    "location": "Algiers, Capital",
    "employees": "50-200 employees",
    "founded": "2015",
    "website": "www.techinfo.dz",
    "description":
        "A leading company in software development and providing integrated technological solutions for companies and institutions in Algeria and the Arab world.",
  };

  @override
  void initState() {
    super.initState();
    // --- Initialize StreamController ---
    _jobsStreamController = StreamController<List<dynamic>>.broadcast();
    _applicantsStreamController = StreamController<List<dynamic>>.broadcast();
    // --- End Initialization ---

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentIndex = _tabController.index;
        });

        // Load applicants data when switching to applicants tab (index 1)
        if (_tabController.index == 1) {
          print("Honecompane: Switched to Applicants tab, refreshing data...");
          _GetAllApplicantsForCompanyJob();
        }
      }
    });

    // تحميل معرف الشركة وجلب البيانات الأولية
    _loadCompanyID();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // --- Dispose StreamController ---
    _jobsStreamController.close();
    _applicantsStreamController.close();
    // --- End Dispose ---
    super.dispose();
  }

  Future<void> _loadCompanyID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // إضافة طباعة للتحقق من القيم الأولية
      print("Honecompane: Loading companyID...");
      print("Honecompane: widget.companyID = ${widget.companyID}");
      print(
          "Honecompane: prefs.getInt('companyID') = ${prefs.getInt('companyID')}");

      int loadedCompanyID = widget.companyID ?? prefs.getInt('companyID') ?? 0;

      // طباعة قيمة companyID النهائية بعد التحديد
      print("Honecompane: Determined companyID = $loadedCompanyID");

      if (mounted) {
        setState(() {
          // استخدام معرف الشركة من الـ widget إذا كان متوفرًا، وإلا استخدام القيمة المخزنة
          companyID = loadedCompanyID;
        });
      } else {
        return; // Don't proceed if not mounted
      }

      // تخزين معرف الشركة الحالي
      if (companyID > 0) {
        prefs.setInt('companyID', companyID);
        print("Honecompane: Stored companyID = $companyID in prefs");
      }

      if (companyID > 0) {
        // طباعة قبل استدعاء الدوال المعتمدة على companyID
        print(
            "Honecompane: companyID is valid ($companyID). Fetching jobs and company data...");
        // تحميل بيانات الشركة وقائمة الوظائف
        await _getCompaneID(); // استدعاء الدالة لجلب بيانات الشركة (wait for it)
        await _getJobsForCompany(); // Fetch initial jobs for the stream
        await _GetAllApplicantsForCompanyJob(); // Fetch initial applicants data
      } else {
        // يمكنك هنا تعيين حالة خطأ أو عرض رسالة للمستخدم
        print(
            "Honecompane: No valid companyID found (companyID = $companyID).");
        if (mounted) {
          setState(() {
            _fetchedCompanyData =
                null; // مسح البيانات القديمة إذا كان المعرف غير صالح
          });
          _jobsStreamController
              .addError("No valid companyID found"); // Add error to stream
        }
      }
    } catch (e) {
      print("Honecompane: Error loading companyID: $e");
      if (mounted) {
        setState(() {
          _fetchedCompanyData = null; // مسح البيانات في حالة حدوث خطأ
        });
        _jobsStreamController
            .addError("Error loading companyID: $e"); // Add error to stream
      }
    }
  }

  Future<void> _getJobsForCompany() async {
    try {
      if (companyID <= 0) {
        print("Honecompane: Invalid companyID for fetching jobs.");
        _jobsStreamController
            .addError('Invalid companyID'); // Add error to stream
        return;
      }

      print("Honecompane: Fetching jobs for company ID: $companyID");
      final apiServers = ApiServers();
      final http.Response response =
          await apiServers.getJobsForCompany(companyID);

      print("Honecompane: Get jobs response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _currentJobs = data; // تخزين الوظائف في المتغير العام
        print("Honecompane: Successfully fetched ${_currentJobs.length} jobs.");
      } else if (response.statusCode == 404) {
        print(
            "Honecompane: No jobs found for company (404). Setting empty list.");
        _currentJobs = []; // Set to empty list if 404
      } else {
        print(
            "Honecompane: Failed to load jobs, status code: ${response.statusCode}");
        // Add error to the stream with status code
        _jobsStreamController
            .addError('Failed to load jobs: ${response.statusCode}');
        return; // Exit if fetch failed with other errors
      }
    } catch (e) {
      print("Honecompane: Error fetching jobs: $e");
      _jobsStreamController
          .addError('Error fetching jobs: $e'); // Add error to stream
      return; // Exit on exception
    }

    // Add the fetched data (or empty list on 404) to the stream
    if (!_jobsStreamController.isClosed) {
      _jobsStreamController.add(_currentJobs);
    }
  }

  Future<void> _getCompaneID() async {
    if (companyID <= 0) {
      print("Honecompane: Invalid companyID for fetching company data.");
      if (mounted) {
        setState(() {
          _fetchedCompanyData = null; // Clear data if ID is invalid
        });
      }
      return;
    }

    print("Honecompane: Fetching company profile data for ID: $companyID");
    if (mounted) {
      setState(() {
        _fetchedCompanyData = null; // Show loading state by clearing old data
      });
    }

    try {
      final apiServers = ApiServers();
      // Assuming ApiServers has a method getCompaneID (or similar)
      final http.Response response = await apiServers.getCompaneID(companyID);

      print(
          "Honecompane: Get company profile response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          // Check if widget is still mounted before calling setState
          setState(() {
            _fetchedCompanyData = data; // Update company data
          });
        }
        print(
            "Honecompane: Successfully fetched company profile: $_fetchedCompanyData");
      } else {
        print(
            "Honecompane: Failed to load company profile: ${response.statusCode} - ${response.body}");
        if (mounted) {
          // Check if widget is still mounted
          setState(() {
            _fetchedCompanyData = null; // Clear data on failure
          });
        }
      }
    } catch (e) {
      print("Honecompane: Error fetching company profile: $e");
      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _fetchedCompanyData = null; // Clear data on error
        });
      }
    }
  }

  // دالة لجلب المتقدمين للوظائف مع معالجة أفضل للأخطاء
  Future<void> _GetAllApplicantsForCompanyJob() async {
    List<dynamic> currentApplicants = []; // قائمة مؤقتة لتخزين المتقدمين

    // التحقق من صحة معرف الشركة
    if (companyID <= 0) {
      print("Honecompane: Invalid companyID for fetching applicants.");
      _applicantsStreamController.addError('Invalid companyID');
      return;
    }

    try {
      print("Honecompane: Fetching applicants for company ID: $companyID");
      final apiServers = ApiServers();

      // محاولة جلب البيانات مع مهلة زمنية لتجنب الانتظار الطويل
      final http.Response response =
          await apiServers.GetAllApplicantsForCompanyJob(companyID).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // إذا انتهت المهلة الزمنية
          throw TimeoutException(
              'Connection timeout. Server took too long to respond.');
        },
      );

      print(
          "Honecompane: Get applicants response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        // نجاح الاستجابة - البيانات تأتي مجمعة حسب الحالة
        final List<dynamic> data = json.decode(response.body);
        print(
            "Honecompane: Successfully fetched applicants data with ${data.length} status groups.");

        // تخزين البيانات المجمعة كما هي
        currentApplicants = data;
      } else if (response.statusCode == 404) {
        // لا يوجد متقدمين
        print(
            "Honecompane: No applicants found for company (404). Setting empty list.");
        currentApplicants = [];
      } else {
        // أخطاء أخرى
        print(
            "Honecompane: Failed to load applicants: ${response.statusCode} - ${response.body}");
        _applicantsStreamController
            .addError('Failed to load applicants: ${response.statusCode}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to load job applicants. Error code: ${response.statusCode}'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  // إعادة المحاولة عند النقر على الزر
                  _GetAllApplicantsForCompanyJob();
                },
              ),
            ),
          );
        }
        return;
      }
    } catch (e) {
      // معالجة الأخطاء المختلفة بشكل مختلف
      String errorMessage = 'Error fetching applicants';

      if (e is TimeoutException) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e is SocketException) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e is FormatException) {
        errorMessage = 'Data format error. Server returned invalid data.';
      } else {
        errorMessage = 'Error fetching applicants: $e';
      }

      print("Honecompane: $errorMessage");
      _applicantsStreamController.addError(errorMessage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error loading job applicants: ${e.toString().split("Exception:").last}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                // إعادة المحاولة عند النقر على الزر
                _GetAllApplicantsForCompanyJob();
              },
            ),
          ),
        );
      }
      return;
    }

    // إضافة البيانات إلى الـ stream إذا لم يتم إغلاقه
    if (!_applicantsStreamController.isClosed) {
      _applicantsStreamController.add(currentApplicants);
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isMediumScreen =
        screenSize.width >= 600 && screenSize.width < 900;
    final bool isLargeScreen = screenSize.width >= 900;

    // استخدام البيانات المحملة إن وجدت، وإلا استخدام البيانات المؤقتة
    final displayCompanyData = _fetchedCompanyData ?? _placeholderCompanyData;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: Text(
          "Company control panel",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            // تعديل حجم النص حسب حجم الشاشة
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        centerTitle: true,
        actions: [
          // استخدام الدالة الجديدة لإنشاء أزرار الشريط العلوي
          _buildAppBarActions(),
        ],
      ),
      body: Column(
        children: [
          // ملخص الشركة
          _buildCompanySummary(
              displayCompanyData, isSmallScreen, isMediumScreen),

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
                Tab(text: "Jobs", icon: Icon(Icons.work, size: 24)),
                Tab(text: "Applicants", icon: Icon(Icons.people, size: 24)),
                Tab(
                    text: "Company Profile",
                    icon: Icon(Icons.business, size: 24)),
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

                // علامة تبويب ملف الشركة
                _buildCompanyProfileTab(displayCompanyData, isSmallScreen,
                    isMediumScreen, isLargeScreen),
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
                // --- This logic remains the same ---
                Navigator.of(context)
                    .push<Map<String, dynamic>?>(// توقع إرجاع الوظيفة المضافة
                        MaterialPageRoute(
                            builder: (context) => AddJob(
                                  companyID: companyID,
                                )))
                    .then((newJobData) {
                  // هذه الكتلة تنفذ عندما يتم إغلاق شاشة AddJob
                  if (newJobData != null) {
                    print(
                        "Honecompane: Job added successfully, updating stream directly.");
                    // إضافة الوظيفة الجديدة مباشرة إلى القائمة الحالية وتحديث الـ stream
                    setState(() {
                      _currentJobs
                          .add(newJobData); // إضافة الوظيفة الجديدة إلى القائمة
                      if (!_jobsStreamController.isClosed) {
                        _jobsStreamController
                            .add(_currentJobs); // تحديث الـ stream
                      }
                    });
                  }
                });
                // --- End modification ---
              },
            )
          : null,
    );
  }

  Widget _buildCompanySummary(Map<String, dynamic> companyData,
      bool isSmallScreen, bool isMediumScreen) {
    Widget logoWidget;
    final String? logoPath = companyData["logoPath"] as String?;

    if (logoPath != null && logoPath.isNotEmpty) {
      logoWidget = Image.network(
        logoPath, // افترض أنه رابط كامل
        width: isMediumScreen ? 50 : 60, // حجم مناسب للصورة داخل الدائرة
        height: isMediumScreen ? 50 : 60,
        fit: BoxFit.cover, // أو BoxFit.contain حسب الحاجة
        errorBuilder: (context, error, stackTrace) {
          // في حالة فشل تحميل الصورة، عرض الأحرف الأولى
          String initials = (companyData["name"]?.length ?? 0) >= 2
              ? companyData["name"].substring(0, 2).toUpperCase()
              : "?";
          if (companyData["name"] == "Loading...") initials = "?";
          return Center(
              child: Text(initials,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMediumScreen ? 20 : 24)));
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child; // اكتمل التحميل
          // عرض مؤشر تحميل دائري أثناء تحميل الصورة
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      // إذا لم يكن هناك logoPath، عرض الأحرف الأولى
      String initials = (companyData["name"]?.length ?? 0) >= 2
          ? companyData["name"].substring(0, 2).toUpperCase()
          : "?";
      if (companyData["name"] == "Loading...") initials = "?";
      logoWidget = Center(
          child: Text(initials,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMediumScreen ? 20 : 24)));
    }

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
              child: ClipRRect(
                // قص الصورة لتناسب الزوايا الدائرية
                borderRadius: BorderRadius.circular(15.0),
                child: logoWidget,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  companyData["name"] ??
                      "Name not available", // Handle null value
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
                      companyData["industry"] ?? "Industry not specified",
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
                      companyData["wilayaInfo"]?['name'] ?? "-",
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
              child: ClipRRect(
                // قص الصورة لتناسب الزوايا الدائرية
                borderRadius: BorderRadius.circular(15.0),
                child: logoWidget,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyData["name"] ??
                        "Name not available", // Handle null value
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
                        companyData["industry"] ?? "Industry not specified",
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
                        companyData["wilayaInfo"]?['name'] ?? "-",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isMediumScreen ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    companyData["description"] ??
                        "No description available", // Handle null value
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
          ],
        ),
      );
    }
  }

  Widget _buildApplicantsTab(
      bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    return StreamBuilder<List<dynamic>>(
      stream: applicantsStream, // Escuchar el stream de solicitantes
      builder: (context, snapshot) {
        // Manejar estados de conexión
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar indicador de carga solo si es la carga inicial
          return Center(
              child: CircularProgressIndicator(color: Color(0xFF36305E)));
        }

        // Manejar errores
        if (snapshot.hasError) {
          return _buildErrorState(
            "Failed to load applicants",
            "An error occurred: ${snapshot.error}",
            Icons.error_outline,
            isSmallScreen,
          );
        }

        // Manejar ausencia de datos
        if (!snapshot.hasData) {
          return _buildEmptyState(
            "No data available",
            "Please refresh the page or check your connection.",
            Icons.signal_wifi_off_outlined,
            isSmallScreen,
          );
        }

        // Manejar datos disponibles - البيانات تأتي مجمعة حسب الحالة
        final List<dynamic> statusGroups = snapshot.data!;

        if (statusGroups.isEmpty) {
          return _buildEmptyState(
            "No applicants",
            "Applicants for posted jobs will appear here",
            Icons.people_outline,
            isSmallScreen,
          );
        }

        // التحقق من وجود متقدمين في أي من المجموعات
        bool hasAnyApplicants = false;
        for (var group in statusGroups) {
          if (group['applicantForCompanyJob'] != null &&
              group['applicantForCompanyJob'] is List &&
              (group['applicantForCompanyJob'] as List).isNotEmpty) {
            hasAnyApplicants = true;
            break;
          }
        }

        if (!hasAnyApplicants) {
          return _buildEmptyState(
            "No applicants",
            "Applicants for posted jobs will appear here",
            Icons.people_outline,
            isSmallScreen,
          );
        }

        // عرض المتقدمين مقسمين حسب الحالة
        return DefaultTabController(
          length: statusGroups.length,
          child: Column(
            children: [
              // شريط التبويب للتنقل بين الحالات المختلفة
              Container(
                color: Colors.white,
                child: TabBar(
                  isScrollable: true,
                  labelColor: const Color(0xFF36305E),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF8A70D6),
                  tabs: statusGroups.map((group) {
                    final String statusText =
                        group['statusAsText'] ?? 'Unknown';
                    final int count =
                        (group['applicantForCompanyJob'] as List?)?.length ?? 0;

                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(statusText),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8A70D6).withAlpha(50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // محتوى التبويب
              Expanded(
                child: TabBarView(
                  children: statusGroups.map((statusGroup) {
                    // استخراج قائمة المتقدمين لهذه الحالة
                    final List<dynamic> applicants =
                        (statusGroup['applicantForCompanyJob'] as List?) ?? [];

                    if (applicants.isEmpty) {
                      return _buildEmptyState(
                        "No applicants ${statusGroup['statusAsText'] ?? ''}",
                        "Applicants with this status will appear here",
                        Icons.people_outline,
                        isSmallScreen,
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
                      itemCount: applicants.length,
                      itemBuilder: (context, index) {
                        // إضافة معلومات الحالة إلى بيانات المتقدم
                        applicants[index]['status'] = statusGroup['status'];
                        applicants[index]['statusAsText'] =
                            statusGroup['statusAsText'];
                        return _buildApplicantCard(
                            applicants[index], isSmallScreen);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanyProfileTab(Map<String, dynamic> companyData,
      bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            companyData['name'] ?? "Company Name",
            style: TextStyle(
              fontSize: isSmallScreen ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF36305E),
            ),
          ),
          const SizedBox(height: 15),
          _buildProfileDetailRow(Icons.business, "Industry",
              companyData['industry'] ?? '-', isSmallScreen),
          _buildProfileDetailRow(Icons.location_on, "Location",
              companyData['wilayaInfo']?['name'] ?? '-', isSmallScreen),
          _buildProfileDetailRow(Icons.group, "Company Size",
              companyData['employees'] ?? '-', isSmallScreen),
          _buildProfileDetailRow(Icons.calendar_today, "Founded",
              companyData['founded'] ?? '-', isSmallScreen),
          _buildProfileDetailRow(
              Icons.link, "Website", companyData['link'] ?? '-', isSmallScreen,
              isLink: true),
          _buildProfileDetailRow(
              Icons.email, "Email", companyData['email'] ?? '-', isSmallScreen),
          _buildProfileDetailRow(
              Icons.phone, "Phone", companyData['phone'] ?? '-', isSmallScreen),
          const SizedBox(height: 25),
          const Text(
            "About the Company",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF36305E),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            companyData['description'] ?? "No company description available.",
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildJobsTab(
      bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    return StreamBuilder<List<dynamic>>(
      stream: jobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xFF36305E)));
        }

        if (snapshot.hasError) {
          print("StreamBuilder Error: ${snapshot.error}");
          return _buildErrorState(
            "Failed to load jobs",
            "An error occurred: ${snapshot.error}",
            Icons.error_outline,
            isSmallScreen,
          );
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            "No job data available",
            "Please try refreshing or check your connection.",
            Icons.signal_wifi_off_outlined,
            isSmallScreen,
          );
        }

        final postedJobs = snapshot.data!;

        if (postedJobs.isEmpty) {
          return _buildEmptyState(
            "No jobs posted yet",
            "Click the '+' button to add your first job opening!",
            Icons.work_off_outlined,
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
            itemCount: postedJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(postedJobs[index], isSmallScreen);
            },
          );
        } else {
          return ListView.builder(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
            itemCount: postedJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(postedJobs[index], isSmallScreen);
            },
          );
        }
      },
    );
  }

  Widget _buildErrorState(
      String title, String subtitle, IconData icon, bool isSmallScreen) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 60 : 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text("Retry"),
            onPressed: _getJobsForCompany,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF36305E),
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    ));
  }

  Widget _buildJobCard(Map<String, dynamic> job, bool isSmallScreen) {
    final bool isActive = _parseBool(job["available"]);

    String postedDateString = "Date N/A";
    if (job["postedDate"] != null) {
      try {
        postedDateString =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(job["postedDate"]));
      } catch (e) {
        postedDateString = job["postedDate"].toString().split('T')[0];
      }
    }

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
                    job["title"] ?? "No Title",
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
                    "Type: ${job["jobType"]?.toString() ?? 'N/A'}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            "Experience ID: ${job["experience"]?.toString() ?? 'N/A'}",
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
                            (job["description"] != null &&
                                    job["description"].isNotEmpty)
                                ? "Description available"
                                : "No description",
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Posted: $postedDateString",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
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
                          Navigator.of(context)
                              .push<Map<String, dynamic>?>(MaterialPageRoute(
                            builder: (context) => AddJob(
                              companyID: companyID,
                              jobToEdit: job,
                            ),
                          ))
                              .then((updatedJobData) {
                            if (updatedJobData != null) {
                              print(
                                  "Honecompane: Job edited successfully, updating stream directly.");
                              // تحديث الوظيفة في القائمة الحالية وتحديث الـ stream
                              setState(() {
                                // البحث عن الوظيفة وتحديثها
                                final int index = _currentJobs.indexWhere(
                                    (j) => j['jobID'] == job['jobID']);
                                if (index != -1) {
                                  _currentJobs[index] = updatedJobData;
                                  if (!_jobsStreamController.isClosed) {
                                    _jobsStreamController
                                        .add(_currentJobs); // تحديث الـ stream
                                  }
                                }
                              });
                            }
                          });
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
                          isActive ? Icons.visibility_off : Icons.visibility,
                          size: isSmallScreen ? 16 : 20,
                        ),
                        label: Text(
                          isActive ? "Hide" : "Publish",
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        ),
                        onPressed: () {
                          print(
                              "Toggle availability for job ID: ${job['jobID']}");
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isActive
                                ? 'Hiding job...'
                                : 'Publishing job...'),
                            duration: Duration(seconds: 1),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? Colors.orange.shade700
                              : Colors.green.shade600,
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

  Widget _buildApplicantCard(
      Map<String, dynamic> applicant, bool isSmallScreen) {
    // Función auxiliar para obtener valores de forma segura
    String getStringValue(dynamic value, String defaultVal) {
      if (value == null) return defaultVal;
      return value.toString();
    }

    // Obtener el estado del solicitante
    String statusStr =
        getStringValue(applicant["statusAsText"], "Under Review");

    // Determinar el color según el estado
    Color statusColor;
    if (applicant["status"] == true) {
      statusColor = Colors.green;
    } else if (applicant["status"] == false) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange; // Estado pendiente
    }

    // Formatear la fecha de solicitud
    String formattedDate = "N/A";
    if (applicant["postedDate"] != null) {
      try {
        final date = DateTime.parse(applicant["postedDate"].toString());
        formattedDate = "${date.year}/${date.month}/${date.day}";
      } catch (e) {
        // Si hay error al parsear, usar el formato original
        formattedDate = applicant["postedDate"].toString().split('T')[0];
      }
    }

    // ID de la solicitud
    String requestID = getStringValue(applicant["requestID"], "");

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navegar a la página de detalles del solicitante
          final int requestID =
              int.tryParse(applicant["requestID"].toString()) ?? 0;
          if (requestID > 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestDetailsPage(requestID: requestID),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid request ID')),
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Título del trabajo y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Título del trabajo
                  Expanded(
                    child: Text(
                      getStringValue(applicant["jobTitle"], "Unknown job"),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                        color: const Color(0xFF36305E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Indicador de estado
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusStr,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Información adicional
              Row(
                children: [
                  // ID de solicitud
                  Icon(
                    Icons.numbers,
                    color: Colors.grey,
                    size: isSmallScreen ? 14 : 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "ID: $requestID",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Fecha de solicitud
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey,
                    size: isSmallScreen ? 14 : 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(
      IconData icon, String label, String value, bool isSmallScreen,
      {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: const Color(0xFF8A70D6), size: isSmallScreen ? 20 : 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                isLink && value != '-'
                    ? InkWell(
                        onTap: () {
                          print("Opening link: $value");
                        },
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 17,
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 17,
                          color: const Color(0xFF36305E),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      String title, String subtitle, IconData icon, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarActions() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          onPressed: () => _switchCompany(context),
          tooltip: "Switch Company",
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {/* Handle notifications */},
          tooltip: "Notifications",
        ),
      ],
    );
  }

  Future<void> _switchCompany(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('companyID');
      await prefs.remove('token');
      await prefs.remove('userType');

      print("Honecompane: Switched company - cleared companyID and token.");

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    } catch (e) {
      print("Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final lowerCaseValue = value.toLowerCase();
      if (lowerCaseValue == 'true') return true;
      if (lowerCaseValue == 'false') return false;
    }
    if (value is int) {
      return value != 0;
    }
    return false;
  }
}
