import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added missing import
import 'package:memoire/Servers/api_servers.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'dart:convert'; // تأكد من استيراد مكتبة dart:convert
import 'package:http/http.dart' as http; // تأكد من استيراد مكتبة http

class AddJob extends StatefulWidget {
  final int companyID;
  final Map<String, dynamic>? jobToEdit; // إضافة متغير للوظيفة المراد تعديلها

  const AddJob({super.key, required this.companyID, this.jobToEdit});

  @override
  State<AddJob> createState() => _AddJobState();
}

class _AddJobState extends State<AddJob> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // القيمة الافتراضية
  List<int> _selectedSkills = [];

  // قائمة المهارات المتاحة
  List<Map<String, dynamic>> _Skill = [];
  Map<String, int> _skillMap = {};

  String? _selectedSkillName;
  List<int> _selectedSkillIDs = [];

  List<dynamic> _jobTypes = [];
  bool _isLoadingJobTypes = false; // متغير لتتبع حالة التحميل

  List<dynamic> _experienceLevels = []; // قائمة لتخزين مستويات الخبرة
  bool _isLoadingExperienceLevels =
      false; // متغير لتتبع حالة تحميل مستويات الخبرة

  // State variables to hold the selected values from dropdowns
  int? _selectedJobTypeId;
  int? _selectedExperienceLevelId;

  Future<void> _getSkills() async {
    try {
      final apiServers = ApiServers();
      final skills = await apiServers.getSkills();

      setState(() {
        _Skill = List<Map<String, dynamic>>.from(skills);

        _skillMap.clear();
        for (var skill in _Skill) {
          if (skill.containsKey('skillID') && skill.containsKey('name')) {
            _skillMap[skill['name']] = skill['skillID'];
            print("Adding skill: ${skill['name']} (${skill['skillID']})");
          } else {
            print("Invalid skill format: $skill");
          }
        }
      });

      print("Loaded ${_Skill.length} skills");

      // Handle empty skills scenario
      if (_Skill.isEmpty) {
        print("No skills found");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("No skills found from the server"),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      print("Error loading skills: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to load skills from the server"),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getSkills(); // استدعاء الدالة عند تهيئة الحالة
    _getJobTypes(); // استدعاء تحميل مستويات الخبرة
    _getExperienceLevels(); // استدعاء تحميل مستويات الخبرة

    // إذا كانت هناك وظيفة للتعديل، قم بتعبئة الحقول
    if (widget.jobToEdit != null) {
      _loadJobDataForEdit();
    }
  }

  // دالة لتحميل بيانات الوظيفة للتعديل
  void _loadJobDataForEdit() {
    final job = widget.jobToEdit!;

    // تعبئة الحقول بالبيانات الحالية
    _titleController.text = job['title'] ?? '';
    _descriptionController.text = job['description'] ?? '';

    // تعيين نوع الوظيفة ومستوى الخبرة
    if (job['jobType'] != null) {
      _selectedJobTypeId = job['jobType'] is int
          ? job['jobType']
          : int.tryParse(job['jobType'].toString());
    }

    if (job['experience'] != null) {
      _selectedExperienceLevelId = job['experience'] is int
          ? job['experience']
          : int.tryParse(job['experience'].toString());
    }

    // تعيين المهارات
    if (job['skills'] != null && job['skills'] is List) {
      _selectedSkillIDs = List<int>.from((job['skills'] as List).map((skill) =>
          skill is int ? skill : int.tryParse(skill.toString()) ?? 0));
    } else if (job['skils'] != null && job['skils'] is List) {
      // للتوافق مع البيانات القديمة التي قد تستخدم 'skils' بدلاً من 'skills'
      _selectedSkillIDs = List<int>.from((job['skils'] as List).map((skill) =>
          skill is int ? skill : int.tryParse(skill.toString()) ?? 0));
    }
  }

  Future<void> _getJobTypes() async {
    setState(() {
      _isLoadingJobTypes = true; // بدء التحميل
    });
    try {
      final apiServers = ApiServers(); // إنشاء نسخة من ApiServers
      final http.Response response = await apiServers.getJobTypes();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // افترض أن الخادم يرجع قائمة مباشرة
          // قد تحتاج إلى تعديل هذا بناءً على هيكل الاستجابة الفعلي
          if (data is List) {
            _jobTypes = data;
            print('Successfully loaded job types: ${_jobTypes.length} types');
          } else {
            print('Unexpected job types data format: ${data.runtimeType}');
            // يمكنك معالجة تنسيقات أخرى هنا إذا لزم الأمر
            _jobTypes = []; // تعيين قائمة فارغة في حالة التنسيق غير المتوقع
          }
        });
      } else {
        // تم التعامل مع الخطأ بالفعل في ApiServers (طباعة وطرح استثناء)
        // يمكنك إضافة معالجة إضافية هنا إذا أردت، مثل إظهار SnackBar
        print('Failed to load job types from API: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load job types. Error code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // التعامل مع الاستثناءات التي تم طرحها من ApiServers أو أخطاء أخرى
      print('Error loading job types: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading job types: $e')),
      );
    } finally {
      setState(() {
        _isLoadingJobTypes = false; // انتهاء التحميل
      });
    }
  }

  Future<void> _getExperienceLevels() async {
    setState(() {
      _isLoadingExperienceLevels = true; // بدء التحميل
    });
    try {
      final apiServers = ApiServers(); // إنشاء نسخة من ApiServers
      final http.Response response = await apiServers.getExperienceLevels();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // افترض أن الخادم يرجع قائمة مباشرة
          // قد تحتاج إلى تعديل هذا بناءً على هيكل الاستجابة الفعلي
          if (data is List) {
            _experienceLevels = data;
            print(
                'Successfully loaded experience levels: ${_experienceLevels.length} levels');
          } else {
            print(
                'Unexpected experience levels data format: ${data.runtimeType}');
            _experienceLevels =
                []; // تعيين قائمة فارغة في حالة التنسيق غير المتوقع
          }
        });
      } else {
        // تم التعامل مع الخطأ بالفعل في ApiServers (طباعة وطرح استثناء)
        print(
            'Failed to load experience levels from API: ${response.statusCode}');
        if (mounted) {
          // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to load experience levels. Error code: ${response.statusCode}')),
          );
        }
        _experienceLevels = []; // تعيين قائمة فارغة في حالة الفشل
      }
    } catch (e) {
      // التعامل مع الاستثناءات التي تم طرحها من ApiServers أو أخطاء أخرى
      print('Error loading experience levels: $e');
      if (mounted) {
        // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading experience levels: $e')),
        );
      }
      _experienceLevels = []; // تعيين قائمة فارغة في حالة الخطأ
    } finally {
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          _isLoadingExperienceLevels = false; // انتهاء التحميل
        });
      }
    }
  }

  bool _isLoading = false;

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation for dropdowns
    if (_selectedJobTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار نوع الوظيفة')),
      );
      return;
    }
    if (_selectedExperienceLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار مستوى الخبرة')),
      );
      return;
    }

    if (_selectedSkillIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار مهارة واحدة على الأقل')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final jobData = {
      "companyID": widget.companyID,
      'title': _titleController.text,
      'jobType': _selectedJobTypeId,
      'experience': _selectedExperienceLevelId,
      'description': _descriptionController.text,
      'skills': _selectedSkillIDs, // تصحيح اسم الحقل من 'skils' إلى 'skills'
    };

    // إذا كانت هناك وظيفة للتعديل، أضف معرف الوظيفة
    if (widget.jobToEdit != null && widget.jobToEdit!.containsKey('jobID')) {
      jobData['jobID'] = widget.jobToEdit!['jobID'];
    }

    print("Submitting job data: $jobData"); // Debug print

    try {
      final apiServers = ApiServers();
      final http.Response response;

      // تحديد ما إذا كانت عملية إضافة أو تعديل
      if (widget.jobToEdit != null && widget.jobToEdit!.containsKey('jobID')) {
        // تعديل وظيفة موجودة
        final int jobId = widget.jobToEdit!['jobID'];
        response = await apiServers.updateJob(jobId, jobData);
        print(
            "Update job response status: ${response.statusCode}"); // Debug print
        print("Update job response body: ${response.body}"); // Debug print
      } else {
        // إضافة وظيفة جديدة
        response = await apiServers.addJob(jobData);
        print("Add job response status: ${response.statusCode}"); // Debug print
        print("Add job response body: ${response.body}"); // Debug print
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        // محاولة الحصول على بيانات الوظيفة من الاستجابة
        Map<String, dynamic> returnedJobData = {};
        try {
          // محاولة تحليل الاستجابة كـ JSON
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            returnedJobData = responseData;
          }
        } catch (e) {
          // إذا فشل التحليل، استخدم البيانات التي تم إرسالها
          print('Error parsing response: $e');
          returnedJobData = jobData;
        }

        // إذا كانت البيانات المرجعة فارغة، استخدم البيانات التي تم إرسالها
        if (returnedJobData.isEmpty) {
          returnedJobData = jobData;
        }

        // إضافة حقل available إذا لم يكن موجودًا
        if (!returnedJobData.containsKey('available')) {
          returnedJobData['available'] = true;
        }

        // إضافة حقل postedDate إذا لم يكن موجودًا
        if (!returnedJobData.containsKey('postedDate')) {
          returnedJobData['postedDate'] = DateTime.now().toIso8601String();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.jobToEdit != null
                  ? 'Job updated successfully'
                  : 'Job added successfully')),
        );

        // العودة مع بيانات الوظيفة
        if (mounted) {
          Navigator.pop(context, returnedJobData);
        }
      } else {
        // Handle error from server
        String errorMessage = widget.jobToEdit != null
            ? 'Failed to update job. Error code: ${response.statusCode}'
            : 'Failed to add job. Error code: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          // Try to extract a more specific message if available
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage += "\n${errorBody['message']}";
          } else if (errorBody is Map && errorBody.containsKey('errors')) {
            // Handle validation errors if backend sends them this way
            errorMessage += "\n${errorBody['errors']}";
          } else {
            errorMessage += "\n${response.body}"; // Fallback to full body
          }
        } catch (e) {
          errorMessage += "\n${response.body}"; // Fallback if body is not JSON
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error submitting job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting job: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.jobToEdit != null ? 'Edit Job' : 'Add new Job',
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
          child: _isLoadingJobTypes || _isLoadingExperienceLevels
              ? Center(
                  child: CircularProgressIndicator(color: Color(0xFF36305E)))
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // عنوان الوظيفة
                            buildLabel('Title Job'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              decoration: buildInputDecoration(
                                'Example: Senior Flutter Developer',
                                Icons.title,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a job title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // نوع الوظيفة
                            buildLabel('Job Type'),
                            const SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<int>(
                                decoration: buildDropdownDecoration(),
                                value: _selectedJobTypeId, // Use state variable
                                hint: Text('Select job type'), // Add hint
                                isExpanded:
                                    true, // Make dropdown take full width
                                items: _jobTypes.map((type) {
                                  // Ensure correct keys are used based on API response
                                  final int id = type['jobTypeID'] ??
                                      type['id'] ??
                                      0; // Adjust keys as needed
                                  final String name = type['jobTypeName'] ??
                                      type['name'] ??
                                      'Unknown type'; // Adjust keys as needed
                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedJobTypeId = value;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Please select a job type'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // مستوى الخبرة
                            buildLabel('Experience Level'),
                            const SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonFormField<int>(
                                decoration: buildDropdownDecoration(),
                                value:
                                    _selectedExperienceLevelId, // Use state variable
                                hint:
                                    Text('Select experience level'), // Add hint
                                isExpanded:
                                    true, // Make dropdown take full width
                                items: _experienceLevels.map((level) {
                                  // Ensure correct keys are used based on API response
                                  final int id = level['experienceLevelID'] ??
                                      level['id'] ??
                                      0; // Adjust keys as needed
                                  final String name = level[
                                          'experienceLevelName'] ??
                                      level['name'] ??
                                      'Unknown level'; // Adjust keys as needed
                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedExperienceLevelId = value;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Please select an experience level'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // وصف الوظيفة
                            buildLabel('Description Job'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: buildInputDecoration(
                                'Write a detailed job description...',
                                Icons.description_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a job description';
                                }
                                if (value.length < 50) {
                                  return 'Description must be at least 50 characters';
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
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey.shade50,
                              ),
                              buttonIcon: Icon(Icons.arrow_drop_down,
                                  color: Color(0xFF36305E)),
                              buttonText: Text("Select skills",
                                  style:
                                      TextStyle(color: Colors.grey.shade700)),
                              chipDisplay: MultiSelectChipDisplay(
                                onTap: (value) {
                                  setState(() {
                                    _selectedSkillIDs.remove(value);
                                  });
                                },
                              ),
                              onConfirm: (values) {
                                setState(() {
                                  _selectedSkillIDs = values.cast<int>();
                                  print(
                                      "✅ Selected skills: $_selectedSkillIDs");
                                });
                              },
                              validator: (values) {
                                if (values == null || values.isEmpty) {
                                  return "Please select at least one skill";
                                }
                                return null;
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
                                  shadowColor:
                                      Color(0xFF36305E).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        widget.jobToEdit != null
                                            ? 'Update job'
                                            : 'Add job',
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
        ));
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
