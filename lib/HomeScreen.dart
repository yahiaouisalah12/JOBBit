import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:memoire/Servers/api_servers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memoire/ApplyJob.dart';

class HomeJobseeker extends StatefulWidget {
  const HomeJobseeker({super.key});

  @override
  State<HomeJobseeker> createState() => _HomescreenState();
}

class _HomescreenState extends State<HomeJobseeker> {
  int _selectedIndex = 0;
  late StreamController<List<dynamic>> _jobsStreamController;
  Stream<List<dynamic>> get jobsStream => _jobsStreamController.stream;
  // قائمة لتخزين الوظائف الحالية
  List<dynamic> _jobs = [];
  bool _isLoading = false;
  // متغير لتخزين بيانات الباحث عن عمل
  dynamic _jobSeekerData;

  @override
  void initState() {
    super.initState();
    // Initialize the StreamController
    _jobsStreamController = StreamController<List<dynamic>>.broadcast();

    // Fetch jobs initially
    getAllJobs();

    // جلب معلومات الباحث عن عمل
    _getjobseekerID();
  }

  // دالة لجلب جميع الوظائف المتاحة بدون تصفية
  Future<void> getAllJobs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apiServers = ApiServers();
      final http.Response response = await apiServers.getAllJobs();

      print("HomeScreen: Get all jobs response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> jobsList = [];

        // التعامل مع الأنواع المختلفة للاستجابة
        if (decodedData is List) {
          // إذا كانت الاستجابة مصفوفة مباشرة
          jobsList = decodedData;
          print("HomeScreen: Received direct jobs list array");
        } else if (decodedData is Map) {
          // إذا كانت استجابة بهيكل مختلف تحتوي على jobLists
          if (decodedData.containsKey('jobLists') &&
              decodedData['jobLists'] is List) {
            jobsList = decodedData['jobLists'];
            if (decodedData.containsKey('categoryName')) {
              print(
                  "HomeScreen: Received category: ${decodedData['categoryName']}");
            }
            print("HomeScreen: Received jobLists inside object");
          } else {
            // البحث عن أي مفتاح يحتوي على مصفوفة
            for (var key in decodedData.keys) {
              if (decodedData[key] is List &&
                  (decodedData[key] as List).isNotEmpty) {
                jobsList = decodedData[key];
                print("HomeScreen: Found jobs list under key: $key");
                break;
              }
            }
          }
        }

        if (jobsList.isEmpty) {
          print("HomeScreen: No jobs found in response");
        } else {
          print("HomeScreen: Found ${jobsList.length} jobs");
          // طباعة مثال للتحقق من البنية
          if (jobsList.isNotEmpty) {
            print("HomeScreen: Example job data: ${jobsList[0]}");
          }
        }

        // Update state and stream
        if (mounted) {
          setState(() {
            _jobs = jobsList;
            _isLoading = false;
            print("HomeScreen: Successfully fetched ${_jobs.length} jobs");
          });

          // Update the StreamController with the new data
          if (!_jobsStreamController.isClosed) {
            _jobsStreamController.add(jobsList);
          }
        }
      } else if (response.statusCode == 404) {
        // Handle case where no jobs found
        print("HomeScreen: No jobs found (404). Setting empty list.");
        if (mounted) {
          setState(() {
            _jobs = []; // Set to empty list if 404
            _isLoading = false;
          });

          // Add empty list to stream
          if (!_jobsStreamController.isClosed) {
            _jobsStreamController.add([]);
          }
        }
      } else {
        // Handle other error status codes
        print(
            "HomeScreen: Failed to load jobs: ${response.statusCode} - ${response.body}");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Add error to stream
          if (!_jobsStreamController.isClosed) {
            _jobsStreamController
                .addError('Failed to load jobs: ${response.statusCode}');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'فشل تحميل الوظائف. رمز الخطأ: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print("HomeScreen: Error when trying to get jobs: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Add error to stream
        if (!_jobsStreamController.isClosed) {
          _jobsStreamController.addError('Error fetching jobs: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الوظائف: $e')),
        );
      }
    }
  }

  // دالة تصفية الوظائف بمعلمات محددة
  Future<void> filterJobs({
    List<int?>? wilayaIDs,
    List<int?>? skillIDs,
    List<int?>? jobTypeIDs,
    List<int?>? jobExperienceIDs,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apiServers = ApiServers();
      final http.Response response = await apiServers.FilterJobs(
        wilayaIDs: wilayaIDs,
        skillIDs: skillIDs,
        jobTypeIDs: jobTypeIDs,
        jobExperienceIDs: jobExperienceIDs,
      );

      print(
          "HomeScreen: Filtered jobs response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> jobsList = [];

        // التعامل مع الأنواع المختلفة للاستجابة
        if (decodedData is List) {
          // إذا كانت الاستجابة مصفوفة مباشرة
          jobsList = decodedData;
          print("HomeScreen: Received direct jobs list array");
        } else if (decodedData is Map) {
          // إذا كانت استجابة بهيكل مختلف تحتوي على jobLists
          if (decodedData.containsKey('jobLists') &&
              decodedData['jobLists'] is List) {
            jobsList = decodedData['jobLists'];
            if (decodedData.containsKey('categoryName')) {
              print(
                  "HomeScreen: Received category: ${decodedData['categoryName']}");
            }
            print("HomeScreen: Received jobLists inside object");
          } else {
            // البحث عن أي مفتاح يحتوي على مصفوفة
            for (var key in decodedData.keys) {
              if (decodedData[key] is List &&
                  (decodedData[key] as List).isNotEmpty) {
                jobsList = decodedData[key];
                print("HomeScreen: Found jobs list under key: $key");
                break;
              }
            }
          }
        }

        if (jobsList.isEmpty) {
          print("HomeScreen: No jobs found in response");
        } else {
          print("HomeScreen: Found ${jobsList.length} jobs");
          // طباعة مثال للتحقق من البنية
          if (jobsList.isNotEmpty) {
            print("HomeScreen: Example job data: ${jobsList[0]}");
          }
        }

        // Update state and stream
        if (mounted) {
          setState(() {
            _jobs = jobsList;
            _isLoading = false;
            print(
                "HomeScreen: Successfully fetched ${_jobs.length} filtered jobs");
          });

          // Update the StreamController with the new data
          if (!_jobsStreamController.isClosed) {
            _jobsStreamController.add(jobsList);
          }
        }
      } else if (response.statusCode == 404) {
        // Handle case where no jobs found
        print("HomeScreen: No filtered jobs found (404). Setting empty list.");
        if (mounted) {
          setState(() {
            _jobs = []; // Set to empty list if 404
            _isLoading = false;
          });

          // Add empty list to stream
          if (!_jobsStreamController.isClosed) {
            _jobsStreamController.add([]);
          }
        }
      } else {
        // Handle other error status codes
        print(
            "HomeScreen: Failed to load filtered jobs: ${response.statusCode} - ${response.body}");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Add error to stream
          if (!_jobsStreamController.isClosed) {
            _jobsStreamController.addError(
                'Failed to load filtered jobs: ${response.statusCode}');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'فشل تحميل الوظائف المفلترة. رمز الخطأ: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print("HomeScreen: Error when trying to get filtered jobs: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Add error to stream
        if (!_jobsStreamController.isClosed) {
          _jobsStreamController.addError('Error fetching filtered jobs: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الوظائف المفلترة: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // إغلاق StreamController عند إنهاء التطبيق
    _jobsStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: Row(
          children: [
            Image.asset('images/Asset 5.png', height: 40),
            const SizedBox(width: 8),
            const Text('JOBBit',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ex. product Designer',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hot vacnsince',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // LinkedIn cards

              // Developer section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Developer :',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: Color(0xFF8A70D6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category filters
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('All Jobs', 0),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Job listings - using StreamBuilder for real-time updates
              StreamBuilder<List<dynamic>>(
                stream: jobsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF36305E)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading jobs: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: getAllJobs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF36305E),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final List<dynamic> jobsData = snapshot.data ?? [];

                  // معالجة البيانات لضمان عرض كافة الوظائف من هيكل البيانات المختلف
                  List<dynamic> processedJobs = [];

                  for (var jobItem in jobsData) {
                    if (jobItem is Map<String, dynamic> &&
                        jobItem.containsKey('jobLists') &&
                        jobItem['jobLists'] is List &&
                        (jobItem['jobLists'] as List).isNotEmpty) {
                      // إضافة جميع الوظائف من jobLists
                      processedJobs.addAll(jobItem['jobLists']);
                    } else {
                      // إضافة الوظيفة العادية
                      processedJobs.add(jobItem);
                    }
                  }

                  if (processedJobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_off,
                              color: Colors.grey, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'No jobs available at the moment',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: processedJobs.length,
                    itemBuilder: (context, index) {
                      return _buildJobCard(processedJobs[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
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
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(dynamic jobData) {
    // طباعة بنية الوظيفة للتحقق
    print("Building job card for: $jobData");

    // التعامل مع مختلف أشكال البيانات
    Map<String, dynamic> job;

    // التحقق إذا كان الكائن يحتوي على قائمة jobLists
    if (jobData is Map<String, dynamic> &&
        jobData.containsKey('jobLists') &&
        jobData['jobLists'] is List &&
        (jobData['jobLists'] as List).isNotEmpty) {
      // استخدام أول وظيفة من القائمة
      job = (jobData['jobLists'][0] as Map<String, dynamic>);
      print("Using first job from jobLists array");
    } else if (jobData is Map<String, dynamic>) {
      // استخدام البيانات كما هي
      job = jobData;
    } else {
      // حالة خطأ أو بيانات غير متوقعة
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Error: Unexpected job data format"),
        ),
      );
    }

    // تحديد ما إذا كانت الوظيفة متاحة
    final bool isActive = job["available"] == true;

    // تنسيق تاريخ النشر
    String postedDateString = "Date N/A";
    if (job["postedDate"] != null) {
      try {
        postedDateString =
            DateTime.parse(job["postedDate"]).toString().split(' ')[0];
      } catch (e) {
        postedDateString = job["postedDate"].toString().split('T')[0];
      }
    }

    // استخراج معلومات الوظيفة
    String companyName = job["companyName"] ?? "Unknown Company";
    String jobTitle = job["title"] ?? "No Title";
    String wilayaName = job["wilayaName"] ?? "N/A";

    // استخراج أيقونات المهارات
    List<dynamic> skillsIcons = [];
    if (job["skillsIconUrl"] != null && job["skillsIconUrl"] is List) {
      skillsIcons = job["skillsIconUrl"];
    }

    // استخراج المهارات
    List<dynamic> skills = [];
    if (job["skills"] != null && job["skills"] is List) {
      skills = job["skills"];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة مع عنوان الوظيفة والموقع
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(
                  0xFF36305E), //isActive ? const Color(0xFF36305E) : Colors.grey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    wilayaName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // محتوى البطاقة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات الشركة
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A70D6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: job["logoPath"] != null &&
                              job["logoPath"].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                job["logoPath"],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      companyName.isNotEmpty
                                          ? companyName[0].toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                companyName.isNotEmpty
                                    ? companyName[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Posted: $postedDateString",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.favorite_border, color: Colors.grey),
                      onPressed: () {
                        // إضافة إلى المفضلة
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to favorites')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // معلومات الموقع والشركة
                Wrap(
                  spacing: 15,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.location_on,
                      "Location: $wilayaName",
                    ),
                    _buildInfoChip(
                      Icons.business,
                      "Company: $companyName",
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // عرض أيقونات المهارات
                if (skillsIcons.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Required Skills:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: skillsIcons.map<Widget>((iconUrl) {
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEBFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.network(
                                iconUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.code,
                                    size: 16,
                                    color: Color(0xFF36305E),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                // عرض المهارات النصية إذا لم تكن هناك أيقونات
                else if (skills.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Required Skills:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEBFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              skill["name"]?.toString() ?? "Unknown Skill",
                              style: const TextStyle(
                                color: Color(0xFF36305E),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // زر التقديم
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // الانتقال إلى صفحة تقديم الطلب
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Applyjob(jobData: job),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF36305E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Apply Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لإنشاء شريحة معلومات
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getjobseekerID() async {
    // استيراد مكتبة SharedPreferences للوصول إلى البيانات المخزنة محلياً
    final prefs = await SharedPreferences.getInstance();
    final jobSeekerID = prefs.getInt('jobSeekerID');

    if (jobSeekerID == null) {
      if (mounted) {
        print('لم يتم العثور على معرف الباحث عن عمل في SharedPreferences');
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final apiServers = ApiServers();
      final response = await apiServers.GetJobSeekerByID(jobSeekerID);

      if (response.statusCode == 200) {
        final jobSeekerData = json.decode(response.body);

        if (mounted) {
          setState(() {
            // تخزين بيانات الباحث عن عمل في متغير حالة
            _jobSeekerData = jobSeekerData;
            _isLoading = false;
            print('تم جلب بيانات الباحث عن عمل بنجاح: ID = $jobSeekerID');
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          print('الباحث عن عمل غير موجود: ID = $jobSeekerID');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          print('فشل في جلب بيانات الباحث عن عمل: ${response.statusCode}');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        print('حدث خطأ أثناء جلب بيانات الباحث عن عمل: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
