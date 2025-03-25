import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:memoire/Compane/HoneCompane.dart';
import 'package:memoire/Servers/api_servers.dart';
import 'dart:convert';

import 'package:memoire/Tabbar.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

class SelfandCompany extends StatefulWidget {
  const SelfandCompany({super.key});

  @override
  State<SelfandCompany> createState() => _SelfState();
}

class _SelfState extends State<SelfandCompany>
    with SingleTickerProviderStateMixin {
  final _selfFormKey = GlobalKey<FormState>();
  final _companyFormKey = GlobalKey<FormState>();
  late TabController _tabController;
  int _currentStep = 0;

  final PageController _selfPageController = PageController();
  final PageController _companyPageController = PageController();

  TextEditingController _Name = TextEditingController();
  TextEditingController _firstName = TextEditingController();
  TextEditingController _lastName = TextEditingController();
  TextEditingController _phoneNumber = TextEditingController();
  TextEditingController _wilya = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _link = TextEditingController();
  TextEditingController _Gender = TextEditingController();
  TextEditingController _Skills = TextEditingController();

  final RegExp _validatePassword =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');
  final RegExp _validateLink =
      RegExp(r'^(https?:\/\/)?([\w.-]+)\.([a-zA-Z]{2,})(\/[^\s]*)?$');
  final RegExp _validatePhone = RegExp(
      r'^(?:\+213|0)(5|6|7)[0-9]{8}$|^(?:\+213|0)(21|23|24|25|26|27|29|31|32|33|34|35|36|37|38|39|41|43|44|45|46|47|48|49)[0-9]{6,7}$');
  final RegExp _validateEmail = RegExp(r'^[a-zA-Z0-9._%+-]{6,30}@gmail\.com$');

  // Add variables to track file upload
  File? _cvFile;
  String? _fileName;
  bool _isUploading = false;
  bool _obscureText = true;

  // إضافة متغير للتحكم في حالة التحميل
  bool _isRegistering = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // قائمة الولايات
  List<dynamic> _wilayas = [];

  List<dynamic> _Skill = [];

  Map<String, int> _skillMap = {};
  String? _selectedSkillName;
  List<int> _selectedSkillIDs = [];

  // خريطة لتخزين معرفات الولايات
  Map<String, int> _wilayaMap = {};
  int _selectedWilayaId = 1; // القيمة الافتراضية

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // استدعاء دالة جلب الولايات عند بدء التطبيق
    _getWilayas();
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _getSkills();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selfPageController.dispose();
    _companyPageController.dispose();
    super.dispose();
  }

  // Simplified file picking method using image_picker
  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _cvFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _isUploading = false;
        });

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("تم رفع الملف بنجاح"),
          backgroundColor: Colors.green,
        ));
      } else {
        // User canceled the picker
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      setState(() {
        _isUploading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("حدث خطأ أثناء رفع الملف"),
        backgroundColor: Colors.red,
      ));
    }
  }

  void goToNextStep() {
    setState(() {
      if (_currentStep < 3) {
        _currentStep++;
        _selfPageController.animateToPage(
          _currentStep,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // دالة للحصول على قائمة الولايات من الخادم

  Future<void> _getSkills() async {
    try {
      final apiServers = ApiServers();
      final skills = await apiServers.getSkills();

      setState(() {
        _Skill = skills;

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

  Future<void> _getWilayas() async {
    try {
      final apiServers = ApiServers();

      final wilayas = await apiServers
          .getWilayas(); // Call the getWilayas method instead of getWilayasListal wilayas = await apiServers

      setState(() {
        _wilayas = wilayas;

        // إنشاء خريطة لتخزين معرفات الولايات
        _wilayaMap.clear(); // مسح القيم السابقة
        for (var wilaya in _wilayas) {
          if (wilaya.containsKey('wilayaID') && wilaya.containsKey('name')) {
            _wilayaMap[wilaya['name']] = wilaya['wilayaID'];
            print("إضافة ولاية: ${wilaya['name']} (${wilaya['wilayaID']})");
          } else {
            print("تنسيق ولاية غير صحيح: $wilaya");
          }
        }
      });

      print("تم تحميل ${_wilayas.length} ولاية");

      // إذا لم يتم تحميل أي ولايات، استخدم قائمة افتراضية
      if (_wilayas.isEmpty) {
        //_loadDefaultWilayas();
      }
    } catch (e) {
      print("خطأ في تحميل الولايات: $e");
      // في حالة حدوث خطأ، استخدم قائمة افتراضية
      //_loadDefaultWilayas();

      // يمكن إضافة إشعار للمستخدم هنا
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("تعذر تحميل الولايات من الخادم. تم استخدام قائمة افتراضية."),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  // دالة لتحميل قائمة افتراضية من الولايات في حالة فشل الاتصال بالخادم

  // إضافة دالة لتسجيل الشركة

  Future<void> _registerJobSeeker() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      // Form validation
      if (_firstName.text.isEmpty ||
          _lastName.text.isEmpty ||
          _email.text.isEmpty ||
          _password.text.isEmpty ||
          _Gender.text.isEmpty ||
          _selectedSkillIDs.isEmpty || // ✅ تأكد من أن المهارة تم اختيارها
          _phoneNumber.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("يرجى ملء جميع الحقول المطلوبة"),
            backgroundColor: Colors.orange));
        return;
      }

      // Validate email
      if (!_validateEmail.hasMatch(_email.text)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("يرجى إدخال بريد إلكتروني صالح من Gmail (6-30 حرفًا)"),
            backgroundColor: Colors.orange));
        return;
      }

      // Validate password
      if (!_validatePassword.hasMatch(_password.text)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل وتتضمن حرفًا كبيرًا وحرفًا صغيرًا ورقمًا ورمزًا خاصًا"),
            backgroundColor: Colors.orange));
        return;
      }

      // Check if CV file is selected
      if (_cvFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("يرجى رفع السيرة الذاتية"),
            backgroundColor: Colors.orange));
        return;
      }

      final apiServers = ApiServers();

      // Parse Gender to integer
      int gender = int.tryParse(_Gender.text) ?? 0;

      // Use selectedSkillID instead of parsing _Skills.text
      List skills = _selectedSkillIDs!;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF36305E)),
              SizedBox(height: 16),
              Text("جاري التسجيل...")
            ],
          ),
        ),
      );

      // Call the API service
      final response = await apiServers.registerJobSeeker(
        _firstName.text,
        _lastName.text,
        _email.text,
        _phoneNumber.text,
        _password.text,
        gender,
        _selectedSkillIDs, // ✅ تمرير المصفوفة مباشرة بعد تعديل الدالة
        _cvFile!.path,
      );

      // Close loading dialog
      Navigator.pop(context);

      print("استجابة الخادم: ${response.statusCode}");
      print("محتوى الاستجابة: ${response.body}");

      // Handle response based on status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successful registration
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("تم التسجيل بنجاح!"), backgroundColor: Colors.green));

        // Navigate to next page
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => Tabbar()));
      } else if (response.statusCode == 400) {
        // Bad request - invalid data
        final errorData = json.decode(response.body);
        String errorMessage = "خطأ في البيانات المدخلة";

        if (errorData != null && errorData.containsKey("message")) {
          errorMessage = errorData["message"];
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage), backgroundColor: Colors.orange));
      } else if (response.statusCode == 409) {
        // Conflict (e.g., email already in use)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("البريد الإلكتروني مستخدم بالفعل"),
            backgroundColor: Colors.orange));
      } else {
        // Other errors
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("حدث خطأ غير متوقع: ${response.statusCode}"),
            backgroundColor: Colors.red));
      }

      // Use selectedSkillID instead of parsing _Skills.text
      if (_selectedSkillIDs.isEmpty) {
        print("خطأ: لم يتم اختيار أي مهارة!");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("يرجى اختيار المهارة"),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      print("Skill IDs to be sent: ${jsonEncode(_selectedSkillIDs)}");
      // تحقق من قيمة الـ ID
    } catch (e) {
      // Handle errors in more detail
      print("Registration error: $e");
      String errorMessage = "حدث خطأ أثناء التسجيل. يرجى المحاولة مرة أخرى.";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Connection refused")) {
        errorMessage = "تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "انتهت مهلة الاتصال بالخادم. يرجى المحاولة لاحقًا.";
      } else if (e.toString().contains("FormatException")) {
        errorMessage = "خطأ في تنسيق البيانات المستلمة من الخادم.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  Future<void> _registerCompany() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      // التحقق من صحة المدخلات
      if (_Name.text.isEmpty ||
          _email.text.isEmpty ||
          _password.text.isEmpty ||
          _phoneNumber.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("يرجى ملء جميع الحقول المطلوبة")));
        setState(() {
          _isRegistering = false;
        });
        return;
      }

      // إنشاء كائن من ApiServers
      final apiServers = ApiServers();

      // استخراج رقم الولاية من النص
      int wilayaID = _wilayaMap[_wilya.text] ?? _selectedWilayaId;
      print("الولاية المحددة: ${_wilya.text} (معرف: $wilayaID)");

      // طباعة الرابط المستخدم
      final url =
          'https://f89e-197-207-173-91.ngrok-free.app/api/Auth/RegisterCompany';
      print('إرسال طلب التسجيل إلى: $url');

      // إنشاء كائن البيانات
      final data = {
        'name': _Name.text,
        'email': _email.text,
        'password': _password.text,
        'phone': _phoneNumber.text,
        'link': _link.text,
        'wilayaID': wilayaID,
      };

      // طباعة البيانات المرسلة
      print('البيانات المرسلة: ${jsonEncode(data)}');

      // استدعاء دالة تسجيل الشركة
      print("جاري إرسال طلب التسجيل...");
      final response = await apiServers.registerCompany(_Name.text, _email.text,
          _password.text, _phoneNumber.text, _link.text, wilayaID);

      print("استجابة الخادم: ${response.statusCode}");
      print("محتوى الاستجابة: ${response.body}");

      // معالجة الاستجابة حسب رمز الحالة
      if (response.statusCode == 200 || response.statusCode == 201) {
        // تسجيل ناجح
        print("Registration successful: ${response.body}");

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("تم التسجيل بنجاح!"), backgroundColor: Colors.green));

        // الانتقال إلى الصفحة التالية
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Honecompane()));
      } else if (response.statusCode == 400) {
        // خطأ في البيانات المرسلة
        final errorData = json.decode(response.body);
        String errorMessage = "خطأ في البيانات المدخلة";

        if (errorData != null && errorData.containsKey("message")) {
          errorMessage = errorData["message"];
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage), backgroundColor: Colors.orange));
      } else if (response.statusCode == 409) {
        // تعارض (مثل البريد الإلكتروني مستخدم بالفعل)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("البريد الإلكتروني مستخدم بالفعل"),
            backgroundColor: Colors.orange));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // غير مصرح
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("غير مصرح لك بالتسجيل"),
            backgroundColor: Colors.red));
      } else if (response.statusCode >= 500) {
        // خطأ في الخادم
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("حدث خطأ في الخادم. يرجى المحاولة لاحقًا"),
            backgroundColor: Colors.red));
      } else {
        // حالات أخرى
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("حدث خطأ غير متوقع: ${response.statusCode}"),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      // معالجة الأخطاء بشكل أكثر تفصيلاً
      print("Registration error: $e");
      String errorMessage = "حدث خطأ أثناء التسجيل. يرجى المحاولة مرة أخرى.";

      if (e.toString().contains("SocketException") ||
          e.toString().contains("Connection refused")) {
        errorMessage = "تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.";
      } else if (e.toString().contains("TimeoutException")) {
        errorMessage = "انتهت مهلة الاتصال بالخادم. يرجى المحاولة لاحقًا.";
      } else if (e.toString().contains("FormatException")) {
        errorMessage = "خطأ في تنسيق البيانات المستلمة من الخادم.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF36305E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 160,
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  "Welcome Back? ",
                  style: TextStyle(color: Colors.white, fontSize: 40),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    SizedBox(height: 2),
                    TabBar(
                      controller: _tabController,
                      labelColor: Color(0xFF36305E),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF36305E),
                      tabs: [
                        Tab(
                          text: "JobSeeker",
                          icon: Icon(Icons.person),
                        ),
                        Tab(
                          text: "Company",
                          icon: Icon(Icons.business),
                        ),
                      ],
                    ),
                    Container(
                      height: 500,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Self Tab Content
                          SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: _selfFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Progress tabs
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentStep = 0;
                                                _selfPageController
                                                    .jumpToPage(0);
                                              });
                                            },
                                            child: Text(
                                              "Import your CV",
                                              style: TextStyle(
                                                color: _currentStep == 0
                                                    ? Color(0xFF36305E)
                                                    : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentStep = 1;
                                                _selfPageController
                                                    .jumpToPage(1);
                                              });
                                            },
                                            child: Text(
                                              "Personal Info",
                                              style: TextStyle(
                                                color: _currentStep == 1
                                                    ? Color(0xFF36305E)
                                                    : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentStep = 2;
                                                _selfPageController
                                                    .jumpToPage(2);
                                              });
                                            },
                                            child: Text(
                                              "Personal Exp",
                                              style: TextStyle(
                                                color: _currentStep == 2
                                                    ? Color(0xFF36305E)
                                                    : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentStep = 3;
                                                _selfPageController
                                                    .jumpToPage(3);
                                              });
                                            },
                                            child: Text(
                                              "Complete Reg",
                                              style: TextStyle(
                                                color: _currentStep == 3
                                                    ? Color(0xFF36305E)
                                                    : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),

                                    // PageView to handle different steps
                                    Container(
                                      height: 330,
                                      child: PageView(
                                        controller: _selfPageController,
                                        physics: NeverScrollableScrollPhysics(),
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentStep = index;
                                          });
                                        },
                                        children: [
                                          // Import CV page - MODIFIED SECTION
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Import your CV :",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 15),
                                              // New CV upload area with image picker functionality
                                              GestureDetector(
                                                onTap: _pickFile,
                                                child: Container(
                                                  height: 200,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey,
                                                      style: BorderStyle.solid,
                                                      width: 1.5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: _cvFile != null
                                                      ? Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            _fileName!
                                                                        .toLowerCase()
                                                                        .endsWith(
                                                                            '.jpg') ||
                                                                    _fileName!
                                                                        .toLowerCase()
                                                                        .endsWith(
                                                                            '.jpeg') ||
                                                                    _fileName!
                                                                        .toLowerCase()
                                                                        .endsWith(
                                                                            '.png')
                                                                ? ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    child: Image
                                                                        .file(
                                                                      _cvFile!,
                                                                      height:
                                                                          100,
                                                                      width:
                                                                          100,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  )
                                                                : Icon(
                                                                    Icons
                                                                        .description,
                                                                    size: 50,
                                                                    color: Colors
                                                                        .blue,
                                                                  ),
                                                            SizedBox(
                                                                height: 10),
                                                            Text(
                                                              _fileName ??
                                                                  'CV Selected',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: 10),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                ElevatedButton
                                                                    .icon(
                                                                  onPressed:
                                                                      _pickFile,
                                                                  icon: Icon(Icons
                                                                      .refresh),
                                                                  label: Text(
                                                                      'Change'),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Color(
                                                                            0xFF36305E),
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                ElevatedButton
                                                                    .icon(
                                                                  onPressed:
                                                                      () {
                                                                    // Move to next step after CV is selected
                                                                    setState(
                                                                        () {
                                                                      _currentStep =
                                                                          1;
                                                                      _selfPageController
                                                                          .animateToPage(
                                                                        1,
                                                                        duration:
                                                                            Duration(milliseconds: 300),
                                                                        curve: Curves
                                                                            .easeInOut,
                                                                      );
                                                                    });
                                                                  },
                                                                  icon: Icon(Icons
                                                                      .arrow_forward),
                                                                  label: Text(
                                                                      'Next'),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .green,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        )
                                                      : _isUploading
                                                          ? Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                color: Color(
                                                                    0xFF36305E),
                                                              ),
                                                            )
                                                          : Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .file_upload_outlined,
                                                                  size: 60,
                                                                  color: Color(
                                                                      0xFF36305E),
                                                                ),
                                                                SizedBox(
                                                                    height: 15),
                                                                Text(
                                                                  "اضغط هنا لرفع ملف السيرة الذاتية",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Color(
                                                                        0xFF36305E),
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 10),
                                                                Text(
                                                                  "يمكنك رفع صورة أو ملف PDF أو DOC",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Personal Info page
                                          SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Personal Information:",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _firstName,
                                                  decoration: InputDecoration(
                                                    labelText: "Fist Name",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _lastName,
                                                  decoration: InputDecoration(
                                                    labelText: "Last Name",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _email,
                                                  decoration: InputDecoration(
                                                    labelText: "ُEmail",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _password,
                                                  decoration: InputDecoration(
                                                    labelText: "Password",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 15,
                                                ),
                                                TextFormField(
                                                  controller: _phoneNumber,
                                                  decoration: InputDecoration(
                                                    labelText: "Phone Number",
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        "Enter Algerian phone number",
                                                    errorStyle: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.phone,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return "Phone number is required";
                                                    }
                                                    if (!_validatePhone
                                                        .hasMatch(value)) {
                                                      return "Enter a valid Algerian phone number";
                                                    }
                                                    return null;
                                                  },
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                ),
                                                SizedBox(height: 15),
                                                DropdownButtonFormField<String>(
                                                  decoration: InputDecoration(
                                                    labelText: "Gender",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                  items: [
                                                    DropdownMenuItem(
                                                        value: "0",
                                                        child: Text("Male")),
                                                    DropdownMenuItem(
                                                        value: "1",
                                                        child: Text("Female")),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _Gender.text =
                                                          value ?? "0";
                                                    });
                                                  },
                                                  value: _Gender.text.isNotEmpty
                                                      ? _Gender.text
                                                      : null,
                                                ),
                                                SizedBox(height: 15),
                                              ],
                                            ),
                                          ),

                                          // Personal Experience page
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "What is your Expertise?",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 15),
                                              MultiSelectDialogField(
                                                items: _skillMap.keys
                                                    .map((String skillName) {
                                                  return MultiSelectItem<int>(
                                                      _skillMap[skillName]!,
                                                      skillName);
                                                }).toList(),
                                                title: Text("اختر المهارات"),
                                                selectedColor: Colors.blue,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                buttonIcon:
                                                    Icon(Icons.arrow_drop_down),
                                                buttonText:
                                                    Text("اختر المهارات"),
                                                onConfirm: (values) {
                                                  setState(() {
                                                    _selectedSkillIDs =
                                                        values.cast<int>();
                                                    print(
                                                        "✅ المهارات المختارة: $_selectedSkillIDs");
                                                  });
                                                },
                                              ),
                                              SizedBox(height: 15),
                                              TextFormField(
                                                decoration: InputDecoration(
                                                  labelText:
                                                      "Years of Experience",
                                                  border: OutlineInputBorder(),
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                              SizedBox(
                                                height: 15,
                                              ),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 50,
                                                child: ElevatedButton(
                                                  onPressed: _isRegistering
                                                      ? null // تعطيل الزر أثناء التسجيل
                                                      : _registerJobSeeker,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color(0xFF36305E),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Register JobSeeker",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Complete Registration page
                                          SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Confirm Registration",
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                SizedBox(height: 20),

                                                // معلومات JobSeeker
                                                Container(
                                                  padding: EdgeInsets.all(15),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          "JobSeeker Information:",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16)),
                                                      SizedBox(height: 10),
                                                      Row(
                                                        children: [
                                                          Text("First Name: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_firstName
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _firstName
                                                                  .text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Last Name: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_lastName
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _lastName.text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Email: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_email
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _email.text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Phone: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_phoneNumber
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _phoneNumber
                                                                  .text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Gender: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_Gender
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _Gender.text),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 20),

                                                // قسم المهارات
                                                // قسم المهارات
                                                Container(
                                                  padding: EdgeInsets.all(15),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text("Skills:",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16)),
                                                      SizedBox(height: 10),
                                                      _selectedSkillIDs.isEmpty
                                                          ? Text(
                                                              "No skills provided") // عرض رسالة إذا لم يتم اختيار مهارات
                                                          : Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children:
                                                                  _selectedSkillIDs
                                                                      .map(
                                                                          (skillId) {
                                                                return Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          3),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                          Icons
                                                                              .check,
                                                                          color: Colors
                                                                              .green,
                                                                          size:
                                                                              18),
                                                                      SizedBox(
                                                                          width:
                                                                              5),
                                                                      Text(_skillMap.keys.firstWhere(
                                                                          (key) =>
                                                                              _skillMap[key] ==
                                                                              skillId,
                                                                          orElse: () =>
                                                                              "Unknown Skill")), // عرض اسم المهارة بدلاً من الـ ID
                                                                    ],
                                                                  ),
                                                                );
                                                              }).toList(),
                                                            ),
                                                    ],
                                                  ),
                                                ),

                                                SizedBox(height: 20),

                                                // زر التسجيل
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 50,
                                                  child: ElevatedButton(
                                                    onPressed: _isRegistering
                                                        ? null
                                                        : _registerJobSeeker,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.purple,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    child: _isRegistering
                                                        ? CircularProgressIndicator(
                                                            color: Colors.white)
                                                        : Text(
                                                            "Register JobSeeker",
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white)),
                                                  ),
                                                ),
                                                SizedBox(height: 15),

                                                // زر العودة
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _currentStep = 2;
                                                      _companyPageController
                                                          .jumpToPage(2);
                                                    });
                                                  },
                                                  child: Text(
                                                    "Back to Edit Information",
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF36305E)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Next and Skip buttons
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Company Tab Content
                          SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: _companyFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Progress tabs
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentStep = 0;
                                                _companyPageController
                                                    .jumpToPage(1);
                                              });
                                            },
                                            child: Text(
                                              "Personal Info",
                                              style: TextStyle(
                                                color: _currentStep == 1
                                                    ? Color(0xFF36305E)
                                                    : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentStep = 2;
                                                _companyPageController
                                                    .jumpToPage(2);
                                              });
                                            },
                                            child: Text(
                                              "About Company",
                                              style: TextStyle(
                                                color: _currentStep == 2
                                                    ? Color(0xFF36305E)
                                                    : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentStep = 3;
                                                _companyPageController
                                                    .jumpToPage(3);
                                              });
                                            },
                                            child: Text(
                                              "Complete Reg",
                                              style: TextStyle(
                                                color: _currentStep == 3
                                                    ? Color(0xFF36305E)
                                                    : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),

                                    // PageView to handle different steps
                                    Container(
                                      height: 330,
                                      child: PageView(
                                        controller: _companyPageController,
                                        physics: NeverScrollableScrollPhysics(),
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentStep = index;
                                          });
                                        },
                                        children: [
                                          // Import CV page - MODIFIED SECTION
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 15),
                                            ],
                                          ),

                                          // Personal Info page

                                          SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Personal Information:",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _Name,
                                                  decoration: InputDecoration(
                                                    labelText: "Company Name",
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        "Enter your company name",
                                                    errorStyle: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return "Company name is required";
                                                    }
                                                    if (value.length < 3) {
                                                      return "Company name should be at least 3 characters";
                                                    }
                                                    return null;
                                                  },
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _email,
                                                  decoration: InputDecoration(
                                                    labelText: "Email",
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        "Must be a Gmail account (6-30 characters)",
                                                    errorStyle: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                  keyboardType: TextInputType
                                                      .emailAddress,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return "Email is required";
                                                    }
                                                    if (!_validateEmail
                                                        .hasMatch(value)) {
                                                      return "Enter a valid Gmail address";
                                                    }
                                                    return null;
                                                  },
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _password,
                                                  decoration: InputDecoration(
                                                    labelText: "Password",
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        "Minimum 8 chars with upper, lower, number & special char",
                                                    errorStyle: TextStyle(
                                                        color: Colors.red),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        _obscureText
                                                            ? Icons
                                                                .visibility_off
                                                            : Icons
                                                                .visibility, // تغيير الأيقونة
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _obscureText =
                                                              !_obscureText; // تغيير حالة الإخفاء/الإظهار
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  obscureText: _obscureText,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return "Password is required";
                                                    }
                                                    if (!RegExp(
                                                            r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                                                        .hasMatch(value)) {
                                                      return "Password must have 8+ chars with uppercase, lowercase, number & special char";
                                                    }
                                                    return null;
                                                  },
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                ),
                                                SizedBox(height: 15),
                                                TextFormField(
                                                  controller: _phoneNumber,
                                                  decoration: InputDecoration(
                                                    labelText: "Phone Number",
                                                    border:
                                                        OutlineInputBorder(),
                                                    helperText:
                                                        "Enter Algerian phone number",
                                                    errorStyle: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.phone,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return "Phone number is required";
                                                    }
                                                    if (!_validatePhone
                                                        .hasMatch(value)) {
                                                      return "Enter a valid Algerian phone number";
                                                    }
                                                    return null;
                                                  },
                                                  autovalidateMode:
                                                      AutovalidateMode
                                                          .onUserInteraction,
                                                ),
                                                SizedBox(height: 15),
                                              ],
                                            ),
                                          ),

                                          // Personal Experience page
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "What is your Expertise?",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 15),
                                              DropdownSearch<String>(
                                                popupProps: PopupProps.menu(
                                                  showSearchBox: true,
                                                  searchFieldProps:
                                                      TextFieldProps(
                                                    controller: _wilya,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          "Search for wilaya",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                  ),
                                                  showSelectedItems: true,
                                                ),
                                                items: _wilayas.isNotEmpty
                                                    ? _wilayas
                                                        .map<String>((wilaya) =>
                                                            wilaya['name']
                                                                .toString())
                                                        .toList()
                                                    : ["لا توجد ولايات متاحة"],
                                                dropdownDecoratorProps:
                                                    DropDownDecoratorProps(
                                                  dropdownSearchDecoration:
                                                      InputDecoration(
                                                    labelText: "select wilaya",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(() {
                                                      _wilya.text = value;
                                                      // تحديث معرف الولاية المحدد
                                                      _selectedWilayaId =
                                                          _wilayaMap[value] ??
                                                              1;
                                                      print(
                                                          "تم اختيار الولاية: $value (معرف: $_selectedWilayaId)");
                                                    });
                                                  }
                                                },
                                                selectedItem:
                                                    _wilya.text.isNotEmpty
                                                        ? _wilya.text
                                                        : null,
                                              ),
                                              SizedBox(height: 15),
                                              TextFormField(
                                                controller: _link,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      "Link website company",
                                                  border: OutlineInputBorder(),
                                                  helperText:
                                                      "Enter your company website URL",
                                                  errorStyle: TextStyle(
                                                      color: Colors.red),
                                                ),
                                                keyboardType: TextInputType.url,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return null; // Make it optional
                                                  }
                                                  if (!_validateLink
                                                      .hasMatch(value)) {
                                                    return "Enter a valid website URL";
                                                  }
                                                  return null;
                                                },
                                                autovalidateMode:
                                                    AutovalidateMode
                                                        .onUserInteraction,
                                              ),
                                              SizedBox(height: 25),
                                              // إضافة زر تسجيل الشركة
                                              SizedBox(
                                                width: double.infinity,
                                                height: 50,
                                                child: ElevatedButton(
                                                  onPressed: _isRegistering
                                                      ? null // تعطيل الزر أثناء التسجيل
                                                      : _registerCompany,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color(0xFF36305E),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Register Company",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Complete Registration page
                                          SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Confirm Registration",
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                SizedBox(height: 20),

                                                // معلومات الشركة
                                                Container(
                                                  padding: EdgeInsets.all(15),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          "Company Information:",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16)),
                                                      SizedBox(height: 10),
                                                      Row(
                                                        children: [
                                                          Text("Name: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_Name
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _Name.text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Email: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_email
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _email.text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Phone: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_phoneNumber
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _phoneNumber
                                                                  .text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Wilaya: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_wilya
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _wilya.text),
                                                        ],
                                                      ),
                                                      SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          Text("Website: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Text(_link
                                                                  .text.isEmpty
                                                              ? "Not provided"
                                                              : _link.text),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 20),

                                                // Register Button
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 50,
                                                  child: ElevatedButton(
                                                    onPressed: _isRegistering
                                                        ? null // تعطيل الزر أثناء التسجيل
                                                        : _registerCompany,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: Colors
                                                          .purple, // لون الزر
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    child: _isRegistering
                                                        ? CircularProgressIndicator(
                                                            color: Colors.white)
                                                        : Text(
                                                            "Register Company",
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                  ),
                                                ),
                                                SizedBox(height: 15),
                                                // زر العودة
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _currentStep = 2;
                                                      _companyPageController
                                                          .jumpToPage(2);
                                                    });
                                                  },
                                                  child: Text(
                                                    "Back to Edit Information",
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF36305E)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Next and Skip buttons
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
