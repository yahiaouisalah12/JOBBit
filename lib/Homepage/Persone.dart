import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:memoire/Servers/api_servers.dart';
import 'package:memoire/auth/GetstLogin.dart';

class Person extends StatefulWidget {
  const Person({super.key});

  @override
  State<Person> createState() => _PersonState();
}

class _PersonState extends State<Person> {
  // متغيرات للتحميل وبيانات المستخدم
  bool _isLoading = false;
  dynamic _jobSeekerData;

  @override
  void initState() {
    super.initState();
    // استدعاء دالة جلب بيانات الباحث عن عمل عند تهيئة الصفحة
    _getjobseekerID();
  }

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
        final jobSeekerData = json.decode(response.body);

        // Depuración: Imprimir la estructura de datos recibida
        print("JobSeeker data received: $jobSeekerData");

        // Verificar específicamente las habilidades
        if (jobSeekerData['skills'] != null) {
          print("Skills found: ${jobSeekerData['skills']}");
          print("Skills count: ${(jobSeekerData['skills'] as List).length}");
        } else {
          print("No skills found in the response");
        }

        if (mounted) {
          setState(() {
            // تخزين بيانات الباحث عن عمل في متغير حالة
            _jobSeekerData = jobSeekerData;
            _isLoading = false;
          });
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
          SnackBar(content: Text('$errorMessage')),
        );
        setState(() {
          _isLoading = false;
        });
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
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _getjobseekerID,
            tooltip: "Refresh Data",
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF36305E)),
            )
          : _jobSeekerData == null
              ? const Center(
                  child: Text(
                    'User data not found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // قسم معلومات الملف الشخصي
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF36305E),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            // صورة الملف الشخصي
                            _buildProfileImage(),
                            const SizedBox(height: 15),
                            // اسم المستخدم
                            Text(
                              "${_jobSeekerData['firstName'] ?? ''} ${_jobSeekerData['lastName'] ?? ''}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // وصف المستخدم (يمكن استخدام المهارات الرئيسية)
                            Text(
                              _getJobSeekerSkills(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // أزرار التواصل
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildContactButton(Icons.email, "Email", () {
                                  // فتح تطبيق البريد الإلكتروني
                                  final email = _jobSeekerData['email'];
                                  if (email != null &&
                                      email.toString().isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Opening email: $email')),
                                    );
                                  }
                                }),
                                const SizedBox(width: 20),
                                _buildContactButton(Icons.phone, "Call", () {
                                  // فتح تطبيق الهاتف
                                  final phone = _jobSeekerData['phone'];
                                  if (phone != null &&
                                      phone.toString().isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Calling: $phone')),
                                    );
                                  }
                                }),
                                const SizedBox(width: 20),
                                _buildContactButton(Icons.description, "CV",
                                    () {
                                  // فتح السيرة الذاتية
                                  final cvPath = _jobSeekerData['cvFilePath'];
                                  if (cvPath != null &&
                                      cvPath.toString().isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Opening CV')),
                                    );
                                  }
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // قسم المعلومات الشخصية
                      _buildSectionCard(
                        "Personal Information",
                        [
                          _buildInfoRow(Icons.email, "Email",
                              _jobSeekerData['email'] ?? 'Not available'),
                          _buildInfoRow(Icons.phone, "Phone",
                              _jobSeekerData['phone'] ?? 'Not available'),
                          _buildInfoRow(
                              Icons.person,
                              "Gender",
                              _jobSeekerData['gender'] != null &&
                                      _jobSeekerData['gender']
                                              .toString()
                                              .toLowerCase() ==
                                          "male"
                                  ? 'Male'
                                  : (_jobSeekerData['gender'] != null &&
                                          _jobSeekerData['gender']
                                                  .toString()
                                                  .toLowerCase() ==
                                              "female"
                                      ? 'Female'
                                      : 'Not specified')),
                          _buildInfoRow(Icons.calendar_today, "Date of Birth",
                              _formatDate(_jobSeekerData['dateOfBirth'])),
                          _buildInfoRow(
                              Icons.location_on,
                              "Location",
                              _jobSeekerData['wilayaInfo'] != null
                                  ? _jobSeekerData['wilayaInfo']['name'] ??
                                      'Not available'
                                  : 'Not available'),
                          if (_jobSeekerData['linkProfileLinkden'] != null &&
                              _jobSeekerData['linkProfileLinkden']
                                  .toString()
                                  .isNotEmpty)
                            _buildInfoRow(Icons.link, "LinkedIn",
                                _jobSeekerData['linkProfileLinkden']),
                          if (_jobSeekerData['linkProfileGithub'] != null &&
                              _jobSeekerData['linkProfileGithub']
                                  .toString()
                                  .isNotEmpty)
                            _buildInfoRow(Icons.code, "GitHub",
                                _jobSeekerData['linkProfileGithub']),
                          if (_jobSeekerData['cvFilePath'] != null &&
                              _jobSeekerData['cvFilePath']
                                  .toString()
                                  .isNotEmpty)
                            _buildInfoRow(Icons.description, "CV", "Available"),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // قسم المهارات
                      _buildSkillsSection(),

                      const SizedBox(height: 15),

                      // قسم الإعدادات
                      _buildSettingsCard(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  // دالة لبناء صورة الملف الشخصي بشكل آمن
  Widget _buildProfileImage() {
    // التحقق من وجود مسار صورة صالح
    String? imagePath = _jobSeekerData['profilePicturePath']?.toString();
    bool hasValidImage = imagePath != null && imagePath.isNotEmpty;

    // إذا لم يكن هناك مسار صورة صالح، عرض أيقونة افتراضية
    if (!hasValidImage) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          size: 50,
          color: Color(0xFF36305E),
        ),
      );
    }

    // محاولة تحميل الصورة مع معالجة الأخطاء
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 100,
          height: 100,
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // صورة افتراضية كخلفية
              const Icon(
                Icons.person,
                size: 50,
                color: Color(0xFFEFEBFF),
              ),
              // محاولة تحميل الصورة من الشبكة
              Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // في حالة حدوث خطأ، عرض أيقونة افتراضية
                  return const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF36305E),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    // تم تحميل الصورة بنجاح
                    return child;
                  }
                  // عرض مؤشر تحميل أثناء تحميل الصورة
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF36305E),
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لإنشاء أزرار التواصل
  Widget _buildContactButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8A70D6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لتنسيق التاريخ
  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) {
      return 'Not available';
    }

    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.toString().split('T')[0];
    }
  }

  // دالة لإنشاء بطاقة قسم
  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 15),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF36305E),
            ),
          ),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  // دالة لإنشاء صف معلومات
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEBFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8A70D6),
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة للحصول على مهارات الباحث عن عمل كنص
  String _getJobSeekerSkills() {
    // Verificar si hay datos disponibles
    if (_jobSeekerData == null) {
      return "Job Seeker";
    }

    // Verificar si existe la clave 'skills'
    if (!_jobSeekerData.containsKey('skills')) {
      return "Job Seeker";
    }

    // Obtener los datos de habilidades
    var skillsData = _jobSeekerData['skills'];

    // Verificar si es nulo o vacío
    if (skillsData == null || (skillsData is List && skillsData.isEmpty)) {
      return "Job Seeker";
    }

    // Asegurarse de que sea una lista
    List<dynamic> skills;
    if (skillsData is List) {
      skills = skillsData;
    } else {
      return "Job Seeker";
    }

    // Extraer los nombres de las habilidades
    List<String> skillNames = [];
    for (var skill in skills) {
      if (skill is Map && skill.containsKey('name')) {
        String? name = skill['name']?.toString();
        if (name != null && name.isNotEmpty) {
          skillNames.add(name);
        }
      }
    }

    // Si no se encontraron nombres válidos
    if (skillNames.isEmpty) {
      return "Job Seeker";
    }

    // Mostrar hasta 2 habilidades
    if (skillNames.length <= 2) {
      return skillNames.join(' • ');
    } else {
      return "${skillNames[0]} • ${skillNames[1]} • ...";
    }
  }

  // دالة لبناء قسم المهارات
  Widget _buildSkillsSection() {
    // Depuración adicional
    print("Building skills section with data: $_jobSeekerData");

    // Verificar si hay habilidades disponibles
    if (_jobSeekerData == null) {
      print("JobSeekerData is null");
      return _buildSectionCard(
        "Skills",
        [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No skills registered - Data is null'),
            ),
          )
        ],
      );
    }

    // Verificar específicamente el campo de habilidades
    if (!_jobSeekerData.containsKey('skills')) {
      print("Skills key not found in data");
      return _buildSectionCard(
        "Skills",
        [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No skills key found in data'),
            ),
          )
        ],
      );
    }

    // Verificar si la lista de habilidades está vacía
    var skillsData = _jobSeekerData['skills'];
    if (skillsData == null || (skillsData is List && skillsData.isEmpty)) {
      print("Skills list is null or empty");
      return _buildSectionCard(
        "Skills",
        [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('No skills registered'),
            ),
          )
        ],
      );
    }

    // Asegurarse de que skillsData sea una lista
    List<dynamic> skills;
    if (skillsData is List) {
      skills = skillsData;
    } else {
      print("Skills is not a list: $skillsData");
      return _buildSectionCard(
        "Skills",
        [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Invalid skills format: $skillsData'),
            ),
          )
        ],
      );
    }

    print("Processing ${skills.length} skills");

    // Crear chips para cada habilidad
    return _buildSectionCard(
      "Skills",
      [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: skills.map<Widget>((skill) {
            print("Processing skill: $skill");
            String skillName = '';

            if (skill is Map) {
              skillName = skill['name']?.toString() ?? 'Unnamed skill';
            } else {
              skillName = skill.toString();
            }

            return Chip(
              backgroundColor: const Color(0xFFEFEBFF),
              label: Text(
                skillName,
                style: const TextStyle(color: Color(0xFF36305E)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // دالة لإنشاء بطاقة الإعدادات
  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 15),
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
          const Text(
            "Settings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF36305E),
            ),
          ),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          _buildSettingRow(Icons.edit, "Edit Profile", () {}),
          _buildSettingRow(Icons.lock, "Change Password", () {}),
          _buildSettingRow(Icons.notifications, "Notifications", () {}),
          _buildSettingRow(Icons.language, "Language", () {}),
          _buildSettingRow(
            Icons.logout,
            "Logout",
            () => _logout(context),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // دالة تسجيل الخروج
  Future<void> _logout(BuildContext context) async {
    try {
      // عرض مربع حوار للتأكيد
      bool confirmLogout = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!confirmLogout) return;

      // عرض مؤشر التحميل
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Logging out...')),
        );
      }

      // الحصول على مثيل SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // حذف بيانات المستخدم
      await prefs.remove('jobSeekerID');
      await prefs.remove('token');
      await prefs.remove('userType');

      // تم تسجيل الخروج بنجاح

      // التأكد من أن الواجهة لا تزال موجودة
      final navigator = Navigator.of(context);
      if (mounted) {
        // الانتقال إلى صفحة تسجيل الدخول وإزالة جميع الصفحات السابقة
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // حدث خطأ أثناء تسجيل الخروج
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  // دالة لإنشاء صف إعدادات
  Widget _buildSettingRow(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEBFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFF8A70D6),
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
