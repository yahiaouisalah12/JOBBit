import 'package:flutter/material.dart';

class Person extends StatefulWidget {
  const Person({super.key});

  @override
  State<Person> createState() => _PersonState();
}

class _PersonState extends State<Person> {
  // متغيرات للبيانات الشخصية
  final String _name = "محمد أحمد";
  final String _email = "mohamed.ahmed@example.com";
  final String _phone = "+213 555 123 456";
  final String _location = "الجزائر، ورقلة";
  final String _profession = "مطور واجهة أمامية";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: const Text(
          "الملف الشخصي",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        AssetImage('assets/profile_placeholder.png'),
                  ),
                  const SizedBox(height: 15),
                  // اسم المستخدم
                  Text(
                    _name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // المهنة
                  Text(
                    _profession,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // أزرار التواصل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildContactButton(Icons.email, "البريد"),
                      const SizedBox(width: 20),
                      _buildContactButton(Icons.phone, "اتصال"),
                      const SizedBox(width: 20),
                      _buildContactButton(Icons.message, "رسالة"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // قسم المعلومات الشخصية
            _buildSectionCard(
              "المعلومات الشخصية",
              [
                _buildInfoRow(Icons.email, "البريد الإلكتروني", _email),
                _buildInfoRow(Icons.phone, "رقم الهاتف", _phone),
                _buildInfoRow(Icons.location_on, "الموقع", _location),
              ],
            ),

            const SizedBox(height: 15),

            // قسم المهارات
            _buildSectionCard(
              "المهارات",
              [
                _buildSkillRow("HTML/CSS", 0.9),
                _buildSkillRow("JavaScript", 0.85),
                _buildSkillRow("React", 0.8),
                _buildSkillRow("Flutter", 0.75),
              ],
            ),

            const SizedBox(height: 15),

            // قسم التعليم والخبرة
            _buildSectionCard(
              "التعليم والخبرة",
              [
                _buildExperienceRow(
                  "بكالوريوس علوم الحاسوب",
                  "جامعة ورقلة",
                  "2018 - 2022",
                ),
                _buildExperienceRow(
                  "مطور واجهة أمامية",
                  "شركة تكنولوجيا المعلومات",
                  "2022 - الآن",
                ),
              ],
            ),

            const SizedBox(height: 15),

            // قسم الإعدادات
            _buildSettingsCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // دالة لإنشاء أزرار التواصل
  Widget _buildContactButton(IconData icon, String label) {
    return Column(
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
    );
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
            color: Colors.black.withOpacity(0.05),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء صف مهارة
  Widget _buildSkillRow(String skill, double level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(level * 100).toInt()}%",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: level,
            backgroundColor: const Color(0xFFEFEBFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8A70D6)),
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء صف خبرة أو تعليم
  Widget _buildExperienceRow(String title, String organization, String period) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF8A70D6),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  organization,
                  style: const TextStyle(
                    color: Color(0xFF8A70D6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  period,
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "الإعدادات",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF36305E),
            ),
          ),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          _buildSettingRow(Icons.edit, "تعديل الملف الشخصي", () {}),
          _buildSettingRow(Icons.lock, "تغيير كلمة المرور", () {}),
          _buildSettingRow(Icons.notifications, "الإشعارات", () {}),
          _buildSettingRow(Icons.language, "اللغة", () {}),
          _buildSettingRow(
            Icons.logout,
            "تسجيل الخروج",
            () {},
            color: Colors.red,
          ),
        ],
      ),
    );
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
