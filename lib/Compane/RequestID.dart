import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:memoire/Servers/api_servers.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:intl/intl.dart';

class RequestDetailsPage extends StatefulWidget {
  final int requestID;

  const RequestDetailsPage({
    Key? key,
    required this.requestID,
  }) : super(key: key);

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _requestData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequestDetails();
  }

  // جلب تفاصيل طلب التوظيف
  Future<void> _loadRequestDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiServers = ApiServers();
      final response = await apiServers.getRequestByID(widget.requestID);

      if (response.statusCode == 200) {
        final requestData = json.decode(response.body);

        setState(() {
          _requestData = requestData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في جلب تفاصيل الطلب: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ: $e';
      });
    }
  }

  // تنسيق التاريخ
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'غير متوفر';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (e) {
      return dateString.split('T')[0];
    }
  }

  // فتح رابط
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url);
    try {
      if (!await url_launcher.launchUrl(uri,
          mode: url_launcher.LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('لا يمكن فتح الرابط: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء فتح الرابط: $e')),
        );
      }
    }
  }

  // تغيير حالة الطلب
  Future<void> _updateRequestStatus(bool newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final apiServers = ApiServers();
      final response =
          await apiServers.updateRequestStatus(widget.requestID, newStatus);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // تم تحديث الحالة بنجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus
                  ? 'Request accepted successfully'
                  : 'Request rejected successfully'),
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
          );
        }

        // إعادة تحميل تفاصيل الطلب
        _loadRequestDetails();
      } else {
        // فشل في تحديث الحالة
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to update request status: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من حجم الشاشة
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job Request Details #${widget.requestID}'),
        backgroundColor: const Color(0xFF36305E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Occurred',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadRequestDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF36305E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // حالة الطلب
                      _buildStatusSection(isSmallScreen),
                      const SizedBox(height: 24),

                      // معلومات الوظيفة
                      _buildJobSection(isSmallScreen),
                      const SizedBox(height: 24),

                      // معلومات المتقدم
                      _buildApplicantSection(isSmallScreen),
                      const SizedBox(height: 32),

                      // أزرار الإجراءات
                      if (_requestData?['status'] == null)
                        _buildActionButtons(isSmallScreen),
                    ],
                  ),
                ),
    );
  }

  // قسم حالة الطلب
  Widget _buildStatusSection(bool isSmallScreen) {
    final bool? status = _requestData?['status'];
    final String statusText;
    final Color statusColor;

    if (status == true) {
      statusText = 'Accepted';
      statusColor = Colors.green;
    } else if (status == false) {
      statusText = 'Rejected';
      statusColor = Colors.red;
    } else {
      statusText = 'Pending';
      statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(
            status == true
                ? Icons.check_circle
                : status == false
                    ? Icons.cancel
                    : Icons.pending,
            color: statusColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Applied on: ${_formatDate(_requestData?['date'])}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // قسم معلومات الوظيفة
  Widget _buildJobSection(bool isSmallScreen) {
    final jobInfo = _requestData?['jobInfo'] ?? {};
    final companyInfo = jobInfo['comapnyInfo'] ?? {};
    final skills = jobInfo['skills'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم
            Row(
              children: [
                const Icon(Icons.work, color: Color(0xFF36305E)),
                const SizedBox(width: 8),
                Text(
                  'Job Information',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF36305E),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // عنوان الوظيفة
            Text(
              jobInfo['title'] ?? 'غير متوفر',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // معلومات الشركة
            Row(
              children: [
                if (companyInfo['logoPath'] != null &&
                    companyInfo['logoPath'].toString().isNotEmpty)
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(companyInfo['logoPath']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8A70D6),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                Text(
                  companyInfo['name'] ?? 'غير متوفر',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // تفاصيل الوظيفة
            _buildDetailRow(Icons.location_on, 'Location',
                companyInfo['wilayaInfo']?['name'] ?? 'Not available'),
            _buildDetailRow(Icons.category, 'Job Type',
                jobInfo['jobType'] ?? 'Not available'),
            _buildDetailRow(Icons.work_history, 'Required Experience',
                jobInfo['experience'] ?? 'Not available'),
            _buildDetailRow(Icons.date_range, 'Posted Date',
                _formatDate(jobInfo['postedDate'])),
            const SizedBox(height: 16),

            // وصف الوظيفة
            const Text(
              'Job Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF36305E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              jobInfo['description'] ?? 'No description available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // المهارات المطلوبة
            if (skills.isNotEmpty) ...[
              const Text(
                'Required Skills',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF36305E),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map<Widget>((skill) {
                  return Chip(
                    avatar: skill['iconUrl'] != null &&
                            skill['iconUrl'].toString().isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(skill['iconUrl']),
                            backgroundColor: Colors.transparent,
                          )
                        : null,
                    label: Text(skill['name'] ?? ''),
                    backgroundColor: const Color(0xFF8A70D6).withAlpha(50),
                    labelStyle: const TextStyle(color: Color(0xFF36305E)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // قسم معلومات المتقدم
  Widget _buildApplicantSection(bool isSmallScreen) {
    final jobSeekerInfo = _requestData?['jobSeekerInfo'] ?? {};
    final skills = jobSeekerInfo['skills'] as List? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF36305E)),
                const SizedBox(width: 8),
                Text(
                  'Applicant Information',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF36305E),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // معلومات المتقدم الأساسية
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة المتقدم
                if (jobSeekerInfo['profilePicturePath'] != null &&
                    jobSeekerInfo['profilePicturePath'].toString().isNotEmpty)
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image:
                            NetworkImage(jobSeekerInfo['profilePicturePath']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8A70D6),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(jobSeekerInfo['firstName'],
                            jobSeekerInfo['lastName']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // معلومات المتقدم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${jobSeekerInfo['firstName'] ?? ''} ${jobSeekerInfo['lastName'] ?? ''}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          Icons.location_on,
                          'Location',
                          jobSeekerInfo['wilayaInfo']?['name'] ??
                              'Not available'),
                      _buildDetailRow(Icons.cake, 'Date of Birth',
                          _formatDate(jobSeekerInfo['dateOfBirth'])),
                      _buildDetailRow(Icons.email, 'Email',
                          jobSeekerInfo['email'] ?? 'Not available'),
                      _buildDetailRow(Icons.phone, 'Phone',
                          jobSeekerInfo['phone'] ?? 'Not available'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // الروابط
            if (_hasAnyLink(jobSeekerInfo)) ...[
              const Text(
                'Links',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF36305E),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (jobSeekerInfo['linkProfileLinkden'] != null &&
                      jobSeekerInfo['linkProfileLinkden'].toString().isNotEmpty)
                    _buildLinkButton(
                      'LinkedIn',
                      Icons.link,
                      jobSeekerInfo['linkProfileLinkden'],
                    ),
                  if (jobSeekerInfo['linkProfileGithub'] != null &&
                      jobSeekerInfo['linkProfileGithub'].toString().isNotEmpty)
                    _buildLinkButton(
                      'GitHub',
                      Icons.code,
                      jobSeekerInfo['linkProfileGithub'],
                    ),
                  if (jobSeekerInfo['cvFilePath'] != null &&
                      jobSeekerInfo['cvFilePath'].toString().isNotEmpty)
                    _buildLinkButton(
                      'CV',
                      Icons.description,
                      jobSeekerInfo['cvFilePath'],
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // المهارات
            if (skills.isNotEmpty) ...[
              const Text(
                'Skills',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF36305E),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map<Widget>((skill) {
                  return Chip(
                    avatar: skill['iconUrl'] != null &&
                            skill['iconUrl'].toString().isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(skill['iconUrl']),
                            backgroundColor: Colors.transparent,
                          )
                        : null,
                    label: Text(skill['name'] ?? ''),
                    backgroundColor: const Color(0xFF8A70D6).withAlpha(50),
                    labelStyle: const TextStyle(color: Color(0xFF36305E)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // أزرار الإجراءات
  Widget _buildActionButtons(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateRequestStatus(true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Accept Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _updateRequestStatus(false),
            icon: const Icon(Icons.cancel),
            label: const Text('Reject Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // صف تفاصيل
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // زر رابط
  Widget _buildLinkButton(String label, IconData icon, String url) {
    return OutlinedButton.icon(
      onPressed: () => _launchUrl(url),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF36305E),
        side: const BorderSide(color: Color(0xFF8A70D6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // الحصول على الأحرف الأولى من الاسم
  String _getInitials(String? firstName, String? lastName) {
    String initials = '';

    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }

    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }

    return initials.isEmpty ? '?' : initials;
  }

  // التحقق من وجود أي رابط
  bool _hasAnyLink(Map<String, dynamic> jobSeekerInfo) {
    return (jobSeekerInfo['linkProfileLinkden'] != null &&
            jobSeekerInfo['linkProfileLinkden'].toString().isNotEmpty) ||
        (jobSeekerInfo['linkProfileGithub'] != null &&
            jobSeekerInfo['linkProfileGithub'].toString().isNotEmpty) ||
        (jobSeekerInfo['cvFilePath'] != null &&
            jobSeekerInfo['cvFilePath'].toString().isNotEmpty);
  }
}
