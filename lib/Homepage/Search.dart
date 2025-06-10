import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:memoire/Servers/api_servers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memoire/ApplyJob.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final StreamController<List<dynamic>> _jobsStreamController =
      StreamController<List<dynamic>>.broadcast();
  List<String> _recentSearches = [];
  bool _isLoading = false;
  String _selectedCategory = "All";
  List<dynamic> _jobs = [];

  // قائمة التصنيفات

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _fetchJobs(); // تحميل الوظائف عند فتح الصفحة
  }

  // تحميل عمليات البحث السابقة
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> _searchJobsbytitle() async {
    // التحقق من أن نص البحث غير فارغ
    if (_searchController.text.trim().isEmpty) {
      // إذا كان نص البحث فارغًا، قم بجلب جميع الوظائف
      _fetchJobs();
      return;
    }

    try {
      // عرض مؤشر التحميل
      setState(() {
        _isLoading = true;
      });

      // حفظ البحث في السجل
      _saveSearch(_searchController.text);

      // عرض رسالة للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Searching for: ${_searchController.text}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // استدعاء API للبحث
      final apiServers = ApiServers();
      final response = await apiServers.searchJobs(_searchController.text);

      if (response.statusCode == 200) {
        try {
          // تحليل استجابة JSON
          final List<dynamic> jobsList = json.decode(response.body);

          // تحديث حالة التطبيق
          setState(() {
            _jobs = jobsList;
            _isLoading = false;
            _selectedCategory = "All"; // Reset selected category
          });

          // تحديث Stream
          if (!_jobsStreamController.isClosed) {
            _jobsStreamController.add(jobsList);
          }

          // عرض رسالة للمستخدم
          if (mounted) {
            if (jobsList.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No matching jobs found'),
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Found ${jobsList.length} jobs'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF36305E),
                ),
              );
            }
          }
        } catch (e) {
          // معالجة أخطاء تحليل JSON
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error processing search results: $e'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // خطأ في الخادم
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to search for jobs (${response.statusCode})'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // خطأ غير متوقع
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during search: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // حفظ عملية البحث في السجل
  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    Set<String> searches = Set.from(_recentSearches);
    searches.add(query);
    _recentSearches = searches.take(5).toList(); // حفظ آخر 5 عمليات بحث
    await prefs.setStringList('recentSearches', _recentSearches);
    setState(() {});
  }

  // مسح عمليات البحث السابقة
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentSearches');
    setState(() {
      _recentSearches = [];
    });
  }

  // تحديث الوظائف
  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiServers = ApiServers();
      final response = await apiServers.getAllJobs();

      if (response.statusCode == 200) {
        final List<dynamic> jobs = json.decode(response.body);
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
        _jobsStreamController.add(jobs);
      } else {
        throw Exception('Failed to load jobs');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // تصفية الوظائف حسب التصنيف
  void _filterJobsByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == "All") {
        _jobsStreamController.add(_jobs);
      } else {
        final filteredJobs = _jobs
            .where((job) =>
                job['category']?.toString().toLowerCase() ==
                category.toLowerCase())
            .toList();
        _jobsStreamController.add(filteredJobs);
      }
    });
  }

  // تصفية الوظائف حسب العنوان
  void _filterJobsByTitle(String query) {
    if (query.isEmpty) {
      // If search query is empty, show all jobs
      _jobsStreamController.add(_jobs);
      return;
    }

    // Filter jobs by title
    final filteredJobs = _jobs.where((job) {
      final title = job['title'].toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      return title.contains(searchQuery);
    }).toList();

    // Update the stream with filtered jobs
    _jobsStreamController.add(filteredJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jobsStreamController.close();
    super.dispose();
  }

  // عرض نافذة الفلترة
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filter Options",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF36305E),
              ),
            ),
            SizedBox(height: 20),
            // أضف خيارات التصفية هنا
          ],
        ),
      ),
    );
  }

  // بناء ميزة الوظيفة (الموقع، الراتب، إلخ)
  Widget _buildJobFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Color(0xFF8A70D6)),
        SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // بناء شريحة نوع الوظيفة
  Widget _buildJobTypeChip(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFEFEBFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: Color(0xFF36305E),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: const Text(
          "Search for Jobs",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchJobs,
        color: const Color(0xFF36305E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar - تحسين حقل البحث
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: "Enter job title to search...",
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF8A70D6)),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.filter_list,
                                color: Color(0xFF36305E)),
                            onPressed: () {
                              _showFilterBottomSheet(context);
                            },
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onSubmitted: (value) {
                      // تنفيذ البحث عند الضغط على Enter
                      _searchJobsbytitle();
                    },
                    onChanged: (value) {
                      // تحديث حالة الواجهة عند تغيير النص
                      setState(() {});
                      // يمكن إضافة البحث التلقائي هنا إذا أردت
                      // _searchJobsbytitle();
                    },
                  ),
                ),

                // زر البحث
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // تنفيذ البحث عند النقر على الزر
                      _searchJobsbytitle();
                      // إخفاء لوحة المفاتيح
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text("Search Jobs"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF36305E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Categories
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF36305E),
                  ),
                ),
                const SizedBox(height: 15),

                const SizedBox(height: 25),

                // Recent searches
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Searches",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF36305E),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearRecentSearches,
                      child: const Text(
                        "Clear All",
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
                            "No recent searches",
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

                // Jobs section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == "All"
                          ? "Available Jobs"
                          : "$_selectedCategory Jobs",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF36305E),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchJobs,
                      child: const Text(
                        "Refresh",
                        style: TextStyle(
                          color: Color(0xFF8A70D6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // مؤشر التحميل أو قائمة الوظائف
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF36305E),
                          ),
                        ),
                      )
                    : _jobs.isEmpty
                        ? _buildEmptyJobsMessage()
                        : _buildJobsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // رسالة عندما لا توجد وظائف
  Widget _buildEmptyJobsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Icon(
              Icons.work_off,
              size: 60,
              color: Color(0xFF8A70D6),
            ),
            const SizedBox(height: 16),
            const Text(
              "No jobs found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF36305E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try searching with different keywords or filtering differently",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchJobs,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36305E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قائمة الوظائف
  Widget _buildJobsList() {
    return StreamBuilder<List<dynamic>>(
      stream: _jobsStreamController.stream,
      initialData: _jobs,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error occurred: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyJobsMessage();
        }

        final jobs = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            // تحويل البيانات إلى الشكل المطلوب
            final Map<String, dynamic> jobData = {
              "title": job["title"] ?? "Unknown Job",
              "company":
                  job["companyName"] ?? job["company"] ?? "Unknown Company",
              "logo": job["companyName"]
                      ?.toString()
                      .substring(0, 1)
                      .toUpperCase() ??
                  "C",
              "location":
                  job["wilayaName"] ?? job["location"] ?? "Not specified",
              "salary": job["salary"] ?? "Not specified",
              "type": job["jobType"] ?? job["type"] ?? "Full-time",
              "jobID": job["jobID"],
              "logoPath": job["logoPath"],
              "postedDate": job["postedDate"],
              "skillsIconUrl": job["skillsIconUrl"],
            };
            return _buildJobCard(jobData);
          },
        );
      },
    );
  }

  // دالة لإنشاء شريحة تصنيف
  Widget _buildCategoryChip(String category) {
    bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        _filterJobsByCategory(category);
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
              _searchJobsbytitle();
            },
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء بطاقة وظيفة محسنة
  Widget _buildJobCard(Map<String, dynamic> job) {
    // التحقق من وجود المهارات
    final hasSkills = job["skillsIconUrl"] != null &&
        job["skillsIconUrl"] is List &&
        (job["skillsIconUrl"] as List).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صف الشعار والعنوان
          Row(
            children: [
              // شعار الشركة
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF36305E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: job["logoPath"] != null &&
                        job["logoPath"].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          job["logoPath"],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                job["logo"] ?? "C",
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
                          job["logo"] ?? "C",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 15),
              // معلومات الوظيفة
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      job["company"],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (job["postedDate"] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          "Posted on: ${_formatDate(job["postedDate"].toString())}",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // زر الحفظ
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border,
                  color: Color(0xFF8A70D6),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Job saved to favorites'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          // معلومات إضافية
          const SizedBox(height: 15),
          Row(
            children: [
              _buildJobFeature(Icons.location_on, job["location"]),
              const SizedBox(width: 15),
              if (job["salary"] != null && job["salary"].toString().isNotEmpty)
                _buildJobFeature(Icons.attach_money, job["salary"]),
            ],
          ),

          // المهارات المطلوبة
          if (hasSkills)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (job["skillsIconUrl"] as List).map<Widget>((iconUrl) {
                  return Container(
                    height: 30,
                    width: 30,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBFF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Image.network(
                      iconUrl.toString(),
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.code,
                          size: 16,
                          color: Color(0xFF36305E),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // نوع الوظيفة وأزرار الإجراءات
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildJobTypeChip(job["type"]),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _viewJobDetails(job);
                    },
                    child: const Text(
                      "View Details",
                      style: TextStyle(
                        color: Color(0xFF8A70D6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _applyForJob(job);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF36305E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text("Apply"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تنسيق التاريخ
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString.split('T')[0];
    }
  }

  // عرض تفاصيل الوظيفة
  void _viewJobDetails(Map<String, dynamic> job) {
    // التنقل إلى صفحة تفاصيل الوظيفة
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Applyjob(jobData: job),
      ),
    );
  }

  // التقديم للوظيفة
  void _applyForJob(Map<String, dynamic> job) async {
    try {
      // التحقق من تسجيل الدخول
      final prefs = await SharedPreferences.getInstance();
      final jobSeekerId = prefs.getInt('jobSeekerID');

      if (!mounted) return;

      if (jobSeekerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must login as a job seeker first')),
        );
        return;
      }

      // التنقل إلى صفحة التقديم
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Applyjob(jobData: job),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }
}
