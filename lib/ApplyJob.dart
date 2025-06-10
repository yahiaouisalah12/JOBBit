import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memoire/Servers/api_servers.dart';
import 'package:http/http.dart' as http;

class Applyjob extends StatefulWidget {
  final dynamic jobData;

  const Applyjob({super.key, required this.jobData});

  @override
  State<Applyjob> createState() => _ApplyjobState();
}

class _ApplyjobState extends State<Applyjob> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _jobSeekerData;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _getJobSeekerData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // جلب بيانات الباحث عن عمل
  Future<void> _getJobSeekerData() async {
    final prefs = await SharedPreferences.getInstance();
    final jobSeekerID = prefs.getInt('jobSeekerID');

    if (jobSeekerID == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Job seeker ID not found. Please login.')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiServers = ApiServers();
      final response = await apiServers.GetJobSeekerByID(jobSeekerID);

      if (response.statusCode == 200) {
        final jobSeekerData = json.decode(response.body);

        if (mounted) {
          setState(() {
            _jobSeekerData = jobSeekerData;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching job seeker data: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // تقديم طلب الوظيفة
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jobSeekerID = prefs.getInt('jobSeekerID');

      if (jobSeekerID == null) {
        throw Exception('Job seeker ID not found');
      }

      // تحويل البيانات إلى Map<String, dynamic>
      final Map<String, dynamic> job =
          _convertToStringDynamicMap(widget.jobData);

      // التحقق من وجود معرف الوظيفة
      if (!job.containsKey('jobID') || job['jobID'] == null) {
        throw Exception('Job ID not found');
      }

      // الحصول على معرف الوظيفة
      final jobID = job['jobID'] is int
          ? job['jobID']
          : int.tryParse(job['jobID'].toString());

      if (jobID == null) {
        throw Exception('Invalid job ID');
      }

      // طباعة معلومات التقديم للتحقق
      print('تقديم طلب للوظيفة: jobSeekerID=$jobSeekerID, jobID=$jobID');

      try {
        final apiServers = ApiServers();
        final response = await apiServers.applyForJob(
            jobID: jobID, jobSeekerID: jobSeekerID);

        // طباعة استجابة الخادم للتحقق
        print('استجابة الخادم: ${response.statusCode}');
        print('محتوى الاستجابة: ${response.body}');

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            // تحليل الاستجابة للحصول على رسالة النجاح
            String successMessage =
                'Your application has been submitted successfully!';
            try {
              final responseBody = json.decode(response.body);
              if (responseBody != null && responseBody.containsKey('message')) {
                successMessage = responseBody['message'];
              }
            } catch (e) {
              // تجاهل أخطاء تحليل JSON
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage)),
            );
            Navigator.of(context).pop();
          } else if (response.statusCode == 503) {
            // الخدمة غير متاحة - Service Unavailable
            print(
                'الخادم غير متاح حاليًا (503). محاولة الانتظار وإعادة المحاولة...');

            // عرض رسالة للمستخدم
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server is busy. Retrying...'),
                duration: Duration(seconds: 2),
              ),
            );

            // الانتظار لفترة قصيرة ثم إعادة المحاولة
            await Future.delayed(const Duration(seconds: 3));

            // إعادة المحاولة باستخدام نفس الطريقة
            print('إعادة المحاولة بعد خطأ 503...');
            final retryResponse = await apiServers.applyForJob(
              jobSeekerID: jobSeekerID,
              jobID: jobID,
            );

            print(
                'استجابة إعادة المحاولة بعد 503: ${retryResponse.statusCode}');

            if (retryResponse.statusCode == 200 ||
                retryResponse.statusCode == 201) {
              // تحليل الاستجابة للحصول على رسالة النجاح
              String successMessage =
                  'Your application has been submitted successfully!';
              try {
                final responseBody = json.decode(retryResponse.body);
                if (responseBody != null &&
                    responseBody.containsKey('message')) {
                  successMessage = responseBody['message'];
                }
              } catch (e) {
                // تجاهل أخطاء تحليل JSON
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(successMessage)),
              );
              Navigator.of(context).pop();
            } else {
              // إذا فشلت إعادة المحاولة، ننتقل إلى المحاولة باستخدام مسار مختلف
              print(
                  'فشلت إعادة المحاولة بعد 503. محاولة استخدام مسار مختلف...');
              // استمر إلى المحاولة التالية
            }
          } else if (response.statusCode == 404) {
            // محاولة تقديم الطلب مرة أخرى باستخدام مسار مختلف
            print('محاولة تقديم الطلب مرة أخرى باستخدام مسار مختلف...');

            // استخدام http مباشرة بدلاً من ApiServers مع المسار الصحيح
            final directUrl = "${ApiServers.baseUrl}/api/jobs/ApplayForJob";
            final directResponse = await http.post(
              Uri.parse(directUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept':
                    'text/plain', // تغيير من application/json إلى text/plain كما في curl
              },
              body: json.encode({
                'jobSeekerID': jobSeekerID,
                'jobID': jobID,
              }),
            );

            print('استجابة المحاولة الثانية: ${directResponse.statusCode}');
            print('محتوى الاستجابة الثانية: ${directResponse.body}');

            if (directResponse.statusCode == 200 ||
                directResponse.statusCode == 201) {
              // تحليل الاستجابة للحصول على رسالة النجاح
              String successMessage =
                  'Your application has been submitted successfully!';
              try {
                final responseBody = json.decode(directResponse.body);
                if (responseBody != null &&
                    responseBody.containsKey('message')) {
                  successMessage = responseBody['message'];
                }
              } catch (e) {
                // تجاهل أخطاء تحليل JSON
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(successMessage)),
              );
              Navigator.of(context).pop();
            } else {
              // محاولة قراءة رسالة الخطأ من الاستجابة
              String errorMessage =
                  'Failed to submit application: ${directResponse.statusCode}';
              try {
                final responseBody = json.decode(directResponse.body);
                if (responseBody != null &&
                    responseBody.containsKey('message')) {
                  errorMessage = responseBody['message'];
                }
              } catch (e) {
                // تجاهل أخطاء تحليل JSON
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage)),
              );
            }
          } else {
            // محاولة قراءة رسالة الخطأ من الاستجابة
            String errorMessage =
                'Failed to submit application: ${response.statusCode}';
            try {
              final responseBody = json.decode(response.body);
              if (responseBody != null && responseBody.containsKey('message')) {
                errorMessage = responseBody['message'];
              }
            } catch (e) {
              // تجاهل أخطاء تحليل JSON
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        }
      } catch (e) {
        print('خطأ أثناء تقديم الطلب: $e');

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          // محاولة تقديم الطلب مرة أخرى باستخدام مسار مختلف
          try {
            print(
                'محاولة تقديم الطلب مرة أخرى باستخدام مسار مختلف بعد الخطأ...');

            // استخدام http مباشرة بدلاً من ApiServers مع المسار الصحيح
            final directUrl = "${ApiServers.baseUrl}/api/jobs/ApplayForJob";
            final directResponse = await http.post(
              Uri.parse(directUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept':
                    'text/plain', // تغيير من application/json إلى text/plain كما في curl
              },
              body: json.encode({
                'jobSeekerID': jobSeekerID,
                'jobID': jobID,
              }),
            );

            print(
                'استجابة المحاولة الثانية بعد الخطأ: ${directResponse.statusCode}');
            print('محتوى الاستجابة الثانية بعد الخطأ: ${directResponse.body}');

            if (directResponse.statusCode == 200 ||
                directResponse.statusCode == 201) {
              // تحليل الاستجابة للحصول على رسالة النجاح
              String successMessage =
                  'Your application has been submitted successfully!';
              try {
                final responseBody = json.decode(directResponse.body);
                if (responseBody != null &&
                    responseBody.containsKey('message')) {
                  successMessage = responseBody['message'];
                }
              } catch (e) {
                // تجاهل أخطاء تحليل JSON
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(successMessage)),
              );
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Failed to submit application. Please try again later.')),
              );
            }
          } catch (innerError) {
            print('خطأ في المحاولة الثانية: $innerError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error submitting application: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: const Text(
          "Apply for Job",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF36305E)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات الوظيفة
                  _buildJobInfoCard(),

                  const SizedBox(height: 16),

                  // نموذج التقديم
                  _buildApplicationForm(),
                ],
              ),
            ),
    );
  }

  // بطاقة معلومات الوظيفة
  Widget _buildJobInfoCard() {
    // تحويل البيانات إلى Map<String, dynamic>
    final Map<String, dynamic> job = _convertToStringDynamicMap(widget.jobData);

    // تحسين استخراج معلومات الشركة
    Map<String, dynamic> companyInfo = {};

    // محاولة استخراج معلومات الشركة من مختلف الهياكل المحتملة
    if (job.containsKey('companyInfo') && job['companyInfo'] != null) {
      companyInfo = _convertToStringDynamicMap(job['companyInfo']);
    } else if (job.containsKey('comapnyInfo') && job['comapnyInfo'] != null) {
      companyInfo = _convertToStringDynamicMap(job['comapnyInfo']);
    } else {
      // إنشاء كائن معلومات الشركة من البيانات المتاحة في الوظيفة
      companyInfo = {
        'name': job['companyName'] ?? 'Unknown Company',
        'logoPath': job['logoPath'],
        'wilayaName': job['wilayaName'],
      };
    }
    final List<dynamic> skills = job['skills'] ?? [];

    // طباعة بيانات الوظيفة للتحقق
    print('Job data: $job');
    print('Company info: $companyInfo');

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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
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
          // رأس البطاقة مع عنوان الوظيفة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF36305E),
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
                    job["title"] ?? "No Title",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                    job["jobType"] ?? "N/A",
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A70D6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildCompanyLogo(companyInfo),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCompanyName(companyInfo),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                  ],
                ),

                const SizedBox(height: 16),

                // وصف الوظيفة
                if (job["description"] != null &&
                    job["description"].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Description:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job["description"],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // معلومات إضافية
                Wrap(
                  spacing: 15,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.location_on,
                      "Location: ${_getWilayaName(companyInfo)}",
                    ),
                    _buildInfoChip(
                      Icons.work_history,
                      "Experience: ${job['experience'] ?? 'Not specified'}",
                    ),
                    _buildInfoChip(
                      Icons.business,
                      "Job Type: ${job['jobType'] ?? 'Not specified'}",
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // المهارات المطلوبة
                _buildSkillsSection(job, skills),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // نموذج التقديم
  Widget _buildApplicationForm() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Application Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF36305E),
              ),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 16),

            // معلومات المتقدم
            if (_jobSeekerData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    "Full Name:",
                    "${_jobSeekerData!['firstName'] ?? ''} ${_jobSeekerData!['lastName'] ?? ''}",
                  ),
                  _buildInfoRow(
                    "Email:",
                    _jobSeekerData!['email'] ?? 'Not available',
                  ),
                  _buildInfoRow(
                    "Phone:",
                    _jobSeekerData!['phone'] ?? 'Not available',
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            const SizedBox(height: 16),

            // زر التقديم
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36305E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Submit Application",
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
    );
  }

  // صف معلومات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة لتحويل أي نوع من البيانات إلى Map<String, dynamic>
  Map<String, dynamic> _convertToStringDynamicMap(dynamic data) {
    if (data == null) {
      return {};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      // تحويل Map<dynamic, dynamic> إلى Map<String, dynamic>
      return Map<String, dynamic>.from(
          data.map((key, value) => MapEntry(key.toString(), value)));
    }

    return {};
  }

  // دالة لبناء شعار الشركة
  Widget _buildCompanyLogo(Map<String, dynamic> companyInfo) {
    // البحث عن مسار الشعار في مختلف الهياكل المحتملة
    String? logoPath;

    if (companyInfo.containsKey('logoPath') &&
        companyInfo['logoPath'] != null &&
        companyInfo['logoPath'].toString().isNotEmpty) {
      logoPath = companyInfo['logoPath'].toString();
    } else {
      // تحويل البيانات إلى Map<String, dynamic>
      final Map<String, dynamic> job =
          _convertToStringDynamicMap(widget.jobData);

      if (job.containsKey('logoPath') &&
          job['logoPath'] != null &&
          job['logoPath'].toString().isNotEmpty) {
        logoPath = job['logoPath'].toString();
      }
    }

    // الحصول على الحرف الأول من اسم الشركة
    String companyFirstLetter = _getCompanyName(companyInfo)[0].toUpperCase();

    // إذا كان هناك مسار شعار صالح
    if (logoPath != null && logoPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // في حالة حدوث خطأ، عرض الحرف الأول من اسم الشركة
            return Center(
              child: Text(
                companyFirstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // إذا لم يكن هناك مسار شعار، عرض الحرف الأول من اسم الشركة
      return Center(
        child: Text(
          companyFirstLetter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }
  }

  // دالة للحصول على اسم الشركة
  String _getCompanyName(Map<String, dynamic> companyInfo) {
    // البحث عن اسم الشركة في مختلف الهياكل المحتملة
    if (companyInfo.containsKey('name') &&
        companyInfo['name'] != null &&
        companyInfo['name'].toString().isNotEmpty) {
      return companyInfo['name'].toString();
    }

    // تحويل البيانات إلى Map<String, dynamic>
    final Map<String, dynamic> job = _convertToStringDynamicMap(widget.jobData);

    if (job.containsKey('companyName') &&
        job['companyName'] != null &&
        job['companyName'].toString().isNotEmpty) {
      return job['companyName'].toString();
    }

    return "Unknown Company";
  }

  // دالة للحصول على اسم الولاية بشكل صحيح
  String _getWilayaName(Map<String, dynamic> companyInfo) {
    // التحقق من وجود معلومات الولاية في مختلف الهياكل المحتملة
    if (companyInfo.containsKey('wilayaInfo') &&
        companyInfo['wilayaInfo'] != null) {
      final wilayaInfo = _convertToStringDynamicMap(companyInfo['wilayaInfo']);
      if (wilayaInfo.containsKey('name')) {
        return wilayaInfo['name'] ?? 'غير محدد';
      }
    } else if (companyInfo.containsKey('wilaya') &&
        companyInfo['wilaya'] != null) {
      if (companyInfo['wilaya'] is Map) {
        final wilaya = _convertToStringDynamicMap(companyInfo['wilaya']);
        return wilaya['name'] ?? 'غير محدد';
      } else {
        return companyInfo['wilaya'].toString();
      }
    } else if (companyInfo.containsKey('wilayaID') &&
        companyInfo['wilayaID'] != null) {
      return 'Wilaya #${companyInfo['wilayaID']}';
    }

    // تحويل البيانات إلى Map<String, dynamic>
    final Map<String, dynamic> job = _convertToStringDynamicMap(widget.jobData);

    // التحقق من وجود معلومات الولاية في الوظيفة نفسها
    if (job.containsKey('wilayaName') &&
        job['wilayaName'] != null &&
        job['wilayaName'].toString().isNotEmpty) {
      return job['wilayaName'].toString();
    } else if (job.containsKey('wilayaInfo') && job['wilayaInfo'] != null) {
      final wilayaInfo = _convertToStringDynamicMap(job['wilayaInfo']);
      if (wilayaInfo.containsKey('name')) {
        return wilayaInfo['name'] ?? 'غير محدد';
      }
    } else if (job.containsKey('wilaya') && job['wilaya'] != null) {
      if (job['wilaya'] is Map) {
        final wilaya = _convertToStringDynamicMap(job['wilaya']);
        return wilaya['name'] ?? 'غير محدد';
      } else {
        return job['wilaya'].toString();
      }
    } else if (job.containsKey('wilayaID') && job['wilayaID'] != null) {
      return 'Wilaya #${job['wilayaID']}';
    }

    return 'Not specified';
  }

  // دالة لبناء قسم المهارات
  Widget _buildSkillsSection(Map<String, dynamic> job, List<dynamic> skills) {
    // التحقق من وجود مهارات في الهيكل الأصلي
    if (skills.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Required Skills:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map<Widget>((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (skill["iconUrl"] != null &&
                        skill["iconUrl"].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildSkillIcon(skill["iconUrl"].toString()),
                      ),
                    Text(
                      skill["name"] ?? "Unknown Skill",
                      style: const TextStyle(
                        color: Color(0xFF36305E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // التحقق من وجود مهارات في هيكل skillsIconUrl
    if (job.containsKey('skillsIconUrl') &&
        job['skillsIconUrl'] is List &&
        job['skillsIconUrl'].isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Required Skills:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (job['skillsIconUrl'] as List).map<Widget>((iconUrl) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildSkillIcon(iconUrl.toString()),
                    ),
                    const Text(
                      "Skill",
                      style: TextStyle(
                        color: Color(0xFF36305E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // إذا لم تكن هناك مهارات
    return const SizedBox.shrink();
  }

  // دالة لبناء أيقونة المهارة بشكل آمن
  Widget _buildSkillIcon(String iconUrl) {
    // قائمة بالمواقع المعروفة التي قد تسبب مشاكل
    final List<String> problematicDomains = [
      'cdn.simpleicons.org',
      'cdn-icons-png.flaticon.com/512/873/873155.png',
      'cdn-icons-png.flaticon.com/512/919/919857.png'
    ];

    // التحقق مما إذا كان عنوان URL يحتوي على أي من المواقع المشكلة
    bool isProblematicUrl =
        problematicDomains.any((domain) => iconUrl.contains(domain));

    // إذا كان العنوان مشكلة، استخدم أيقونة افتراضية
    if (isProblematicUrl) {
      return const Icon(
        Icons.code,
        size: 16,
        color: Color(0xFF36305E),
      );
    }

    // محاولة تحميل الصورة مع معالجة الأخطاء
    return Image.network(
      iconUrl,
      width: 16,
      height: 16,
      errorBuilder: (context, error, stackTrace) {
        // في حالة حدوث خطأ، عرض أيقونة افتراضية
        return const Icon(
          Icons.code,
          size: 16,
          color: Color(0xFF36305E),
        );
      },
    );
  }

  // شريحة معلومات
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
}
