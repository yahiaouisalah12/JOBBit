import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // Added missing import
import 'package:memoire/Servers/api_servers.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class Addjob extends StatefulWidget {
  final int companyID;

  const Addjob({super.key, required this.companyID});

  @override
  State<Addjob> createState() => _AddjobState();
}

class _AddjobState extends State<Addjob> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _jobType = 1; // القيمة الافتراضية
  int _experience = 3; // القيمة الافتراضية
  List<int> _selectedSkills = [];

  // قائمة المهارات المتاحة
  List<Map<String, dynamic>> _Skill = [];
  Map<String, int> _skillMap = {};

  String? _selectedSkillName;
  List<int> _selectedSkillIDs = [];

  Future<void> _getSkills() async {
    try {
      final apiServers = ApiServers();
      final skills = await apiServers.getSkills();

      setState(() {
        _Skill = List<Map<String, dynamic>>.from(skills);

        _skillMap.clear();
        for (var skill in _Skill) {
          if (skill.containsKey('skillID') && skill.containsKey('skillName')) {
            _skillMap[skill['skillName']] = skill['skillID'];
            print("إضافة مهارة: ${skill['skillName']} (${skill['skillID']})");
          } else {
            print("تنسيق مهارة غير صحيح: $skill");
          }
        }
      });

      print("تم تحميل ${_Skill.length} مهارة");

      // Handle empty skills scenario
      if (_Skill.isEmpty) {
        print("لم يتم العثور على أي مهارات");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("لم يتم العثور على أي مهارات من الخادم"),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      print("خطأ في تحميل المهارات: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("تعذر تحميل المهارات من الخادم"),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  // قائمة أنواع الوظائف
  final List<Map<String, dynamic>> _jobTypes = [
    {'id': 1, 'name': 'دوام كامل'},
    {'id': 2, 'name': 'دوام جزئي'},
    {'id': 3, 'name': 'عن بعد'},
    {'id': 4, 'name': 'تدريب'},
  ];

  // قائمة مستويات الخبرة
  final List<Map<String, dynamic>> _experienceLevels = [
    {'id': 1, 'name': 'مبتدئ'},
    {'id': 2, 'name': 'متوسط'},
    {'id': 3, 'name': 'متقدم'},
    {'id': 4, 'name': 'خبير'},
  ];

  bool _isLoading = false;

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار مهارة واحدة على الأقل')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final jobData = {
      'companyID': widget.companyID,
      'title': _titleController.text,
      'jobType': _jobType,
      'experience': _experience,
      'description': _descriptionController.text,
      'skils': _selectedSkills,
    };

    try {
      // استخدام ApiServers للإرسال
      final apiServers = ApiServers();
      final response = await apiServers.addJob(jobData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // تم إنشاء الوظيفة بنجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الوظيفة بنجاح')),
        );
        Navigator.pop(context, true); // العودة مع إشارة النجاح
      } else {
        // فشل في إنشاء الوظيفة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إضافة الوظيفة: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new Job',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF36305E),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF36305E).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF36305E)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان الوظيفة
                          buildLabel('Title Job '),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: buildInputDecoration(
                              'Enter job title',
                              Icons.work_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Pleas Entre Title job ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // نوع الوظيفة
                          buildLabel('Type Job '),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<int>(
                              decoration: buildDropdownDecoration(),
                              value: _jobType,
                              items: _jobTypes.map((type) {
                                return DropdownMenuItem<int>(
                                  value: type['id'],
                                  child: Text(type['name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _jobType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          const SizedBox(height: 20),

                          // وصف الوظيفة
                          buildLabel('Description Job'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: buildInputDecoration(
                              'اكتب وصفاً تفصيلياً للوظيفة...',
                              Icons.description_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال وصف الوظيفة';
                              }
                              if (value.length < 50) {
                                return 'الوصف يجب أن يكون 50 حرف على الأقل';
                              }
                              return null;
                            },
                          ),

                          // المهارات المطلوبة
                          buildLabel('Required skills'),
                          const SizedBox(height: 8),
                          MultiSelectDialogField(
                            items: _skillMap.keys.map((String skillName) {
                              return MultiSelectItem<int>(
                                  _skillMap[skillName]!, skillName);
                            }).toList(),
                            title: Text("Choose skills"),
                            selectedColor: Colors.blue,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            buttonIcon: Icon(Icons.arrow_drop_down),
                            buttonText: Text("اختر المهارات"),
                            onConfirm: (values) {
                              setState(() {
                                _selectedSkillIDs = values.cast<int>();
                                print(
                                    "✅ المهارات المختارة: $_selectedSkillIDs");
                              });
                            },
                          ),

                          // زر الإضافة
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _submitJob,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF36305E),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: Color(0xFF36305E).withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Add job',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// Helper methods
Widget buildLabel(String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF36305E),
    ),
  );
}

InputDecoration buildInputDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: Color(0xFF36305E)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Color(0xFF36305E)),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
  );
}

InputDecoration buildDropdownDecoration() {
  return InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    border: InputBorder.none,
  );
}
