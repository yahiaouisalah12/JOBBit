import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memoire/Servers/api_servers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetJobSeekerApplication extends StatefulWidget {
  const GetJobSeekerApplication({super.key});

  @override
  State<GetJobSeekerApplication> createState() => _State();
}

class _State extends State<GetJobSeekerApplication>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  Future<void> _getjobseekerID() async {
    // استيراد مكتبة SharedPreferences للوصول إلى البيانات المخزنة محلياً
    final prefs = await SharedPreferences.getInstance();
    final jobSeekerID = prefs.getInt('jobSeekerID');

    if (jobSeekerID == null) {
      // إذا لم يتم العثور على معرف الباحث عن عمل، انتقل إلى صفحة تسجيل الدخول
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Job seeker ID not found. Please login.')),
        );

        // الانتقال إلى صفحة تسجيل الدخول بعد ثانيتين
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', (Route<dynamic> route) => false);
          }
        });
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
        // تم جلب بيانات الباحث عن عمل بنجاح
        if (mounted) {
          setState(() {
            // تحديث حالة التحميل
            _isLoading = false;
          });
          // جلب طلبات التوظيف بعد تحميل بيانات الباحث عن عمل
          _getJobSeekerApplications();
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job seeker not found')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to fetch job seeker data: ${response.statusCode}')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // إذا كان الخطأ متعلق بعنوان ngrok
        String errorMessage = 'Error fetching job seeker data';

        if (e.toString().contains('ngrok')) {
          errorMessage =
              'The server address (ngrok) seems to have changed. Please update the API address in the app.';
        } else if (e.toString().contains('timeout')) {
          errorMessage =
              'Connection timeout. Please check your internet connection and try again.';
        } else if (e.toString().contains('SocketException')) {
          errorMessage =
              'Could not connect to server. Please check your internet connection and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // متغيرات لتخزين طلبات التوظيف
  List<dynamic> _applications = [];
  late TabController _tabController;

  // حالات الطلبات
  final List<String> _statusLabels = ['All', 'Pending', 'Accepted', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusLabels.length, vsync: this);
    _getjobseekerID();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getJobSeekerApplications() async {
    // الحصول على معرف الباحث عن عمل من التخزين المحلي
    final prefs = await SharedPreferences.getInstance();
    final jobSeekerID = prefs.getInt('jobSeekerID');

    if (jobSeekerID == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please login to view your job applications')),
        );
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final apiServers = ApiServers();
      final response = await apiServers.getJobSeekerApplications(jobSeekerID);

      if (response.statusCode == 200) {
        final List<dynamic> applications = json.decode(response.body);

        setState(() {
          _applications = applications;
          _isLoading = false;
        });

        if (applications.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No job applications found')),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to fetch job applications: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        String errorMessage = 'Error fetching job applications';

        if (e.toString().contains('ngrok')) {
          errorMessage =
              'The server address (ngrok) seems to have changed. Please update the API address in the app.';
        } else if (e.toString().contains('timeout')) {
          errorMessage =
              'Connection timeout. Please check your internet connection and try again.';
        } else if (e.toString().contains('SocketException')) {
          errorMessage =
              'Could not connect to server. Please check your internet connection and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  // تصفية الطلبات حسب الحالة
  List<dynamic> _filterApplicationsByStatus(String status) {
    if (status == 'All') {
      return _applications;
    }

    bool? statusValue;
    if (status == 'Accepted') {
      statusValue = true;
    } else if (status == 'Rejected') {
      statusValue = false;
    } else {
      statusValue = null; // Pending
    }

    return _applications.where((app) {
      if (statusValue == null) {
        return app['status'] == null;
      }
      return app['status'] == statusValue;
    }).toList();
  }

  // تنسيق التاريخ
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }

  // بناء بطاقة طلب توظيف
  Widget _buildApplicationCard(Map<String, dynamic> application) {
    // تحديد حالة الطلب
    String statusText = 'Pending';
    Color statusColor = Colors.orange;

    if (application['status'] != null) {
      if (application['status'] == true) {
        statusText = 'Accepted';
        statusColor = Colors.green;
      } else {
        statusText = 'Rejected';
        statusColor = Colors.red;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    application['jobOffer'] ?? 'Unknown job',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF36305E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(51), // 0.2 * 255 = 51
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  application['company'] ?? 'Unknown company',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Applied on: ${_formatDate(application['appliedOn'] ?? '')}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [],
            ),
          ],
        ),
      ),
    );
  }

  // عرض تفاصيل الوظيفة

  // تنفيذ إلغاء الطلب

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: const Text(
          'Job Applications',
          style: TextStyle(color: Colors.white),
        )),
        backgroundColor: const Color(0xFF36305E),
        bottom: TabBar(
          controller: _tabController,
          tabs: _statusLabels.map((status) => Tab(text: status)).toList(),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('No job applications found'))
              : TabBarView(
                  controller: _tabController,
                  children: _statusLabels.map((status) {
                    final filteredApplications =
                        _filterApplicationsByStatus(status);

                    return filteredApplications.isEmpty
                        ? Center(child: Text('No $status applications'))
                        : ListView.builder(
                            itemCount: filteredApplications.length,
                            itemBuilder: (context, index) {
                              return _buildApplicationCard(
                                  filteredApplications[index]);
                            },
                          );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getJobSeekerApplications,
        backgroundColor: const Color(0xFF36305E),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
