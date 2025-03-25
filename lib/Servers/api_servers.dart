import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiServers {
  // عنوان API الأساسي
  static const String baseUrl = "https://f7ec-154-240-177-190.ngrok-free.app";

  static const String basewilaya =
      "https://f7ec-154-240-177-190.ngrok-free.app/api/Wilayas/GetWilayaByID/:WilayaID";
  static const String baseSkills =
      "https://f7ec-154-240-177-190.ngrok-free.app/api/Skills/GetSkillByID/:SkillID";

  static const String allWilayasUrl =
      "https://f7ec-154-240-177-190.ngrok-free.app/api/Wilayas/GetAllWilayas";

  List<dynamic> _wilaya = [];
  List<dynamic> _Skills = [];

  Future<http.Response> registerCompany(String name, String email,
      String password, String phone, String link, int WilayaID) async {
    return await http.post(
      Uri.parse('$baseUrl/api/Auth/RegisterCompany'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'link': link,
        'wilayaID': WilayaID,
      }),
    );
  }

  Future<http.Response> registerJobSeeker(
    String FirstName,
    String LastName,
    String Email,
    String phone,
    String password,
    int Gender,
    List<int> skills, // قائمة تحتوي على skillID فقط
    String cv,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/Auth/RegisterJobSeeker'),
    );

    request.fields['FirstName'] = FirstName;
    request.fields['LastName'] = LastName;
    request.fields['Email'] = Email;
    request.fields['phone'] = phone;
    request.fields['password'] = password;
    request.fields['Gender'] = Gender.toString();

    // ✅ إرسال المهارات بشكل صحيح
    // Option 1: Send as JSON string
    // جرب استخدام الأحرف الصغيرة

// أو جرب إرسال كل مهارة كرقم وليس كنص
    for (int i = 0; i < skills.length; i++) {
      request.fields['SkillIDs[$i]'] = skills[i].toString();
    }
    print("Sending skills: ${skills.join(',')}");
    // للتأكد مما يتم إرساله

    if (cv.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('cv', cv));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📌 Job Seeker Registration Response: ${response.statusCode}');
      print('📢 Response body: ${response.body}');

      return response;
    } catch (e) {
      print('❌ Error registering job seeker: $e');
      throw Exception('Failed to register job seeker: $e');
    }
  }

  Future<Map<String, dynamic>> _getSkills(int SkiilId) async {
    final url = baseSkills.replaceAll(':SkillID', SkiilId.toString());
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('نوع البيانات المستلمة: ${data.runtimeType}');
      if (data is List) {
        print('عدد العناصر: ${data.length}');
        if (data.isNotEmpty) {
          print('نموذج للعنصر الأول: ${data[0]}');
        }
      } else if (data is Map) {
        print('مفاتيح الخريطة: ${data.keys.toList()}');
        // قد تكون البيانات مغلفة في كائن
        if (data.containsKey('data') ||
            data.containsKey('items') ||
            data.containsKey('skills')) {
          final key = data.containsKey('data')
              ? 'data'
              : data.containsKey('items')
                  ? 'items'
                  : 'skills';
          print('البيانات موجودة تحت المفتاح: $key');
          final items = data[key];
          if (items is List) {
            print('عدد العناصر: ${items.length}');
          }
        }
      }
      return data;
    } else {
      throw Exception('فشل في الحصول على المهارة: ${response.statusCode}');
    }
  }

  // دالة للحصول على ولاية محددة بواسطة المعرف
  Future<Map<String, dynamic>> _getwilaya(int wilayaId) async {
    final url = basewilaya.replaceAll(':WilayaID', wilayaId.toString());
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('نوع البيانات المستلمة: ${data.runtimeType}');
      if (data is List) {
        print('عدد العناصر: ${data.length}');
        if (data.isNotEmpty) {
          print('نموذج للعنصر الأول: ${data[0]}');
        }
      } else if (data is Map) {
        print('مفاتيح الخريطة: ${data.keys.toList()}');
        // قد تكون البيانات مغلفة في كائن
        if (data.containsKey('data') ||
            data.containsKey('items') ||
            data.containsKey('wilayas')) {
          final key = data.containsKey('data')
              ? 'data'
              : data.containsKey('items')
                  ? 'items'
                  : 'wilayas';
          print('البيانات موجودة تحت المفتاح: $key');
          final items = data[key];
          if (items is List) {
            print('عدد العناصر: ${items.length}');
          }
        }
      }
      return data;
    } else {
      throw Exception('فشل في الحصول على الولاية: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getSkills() async {
    try {
      print("بدء تحميل المهارات...");
      final response =
          await http.get(Uri.parse('$baseUrl/api/Skills/GetAllSkills'));
      print('استجابة الخادم للمهارات: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('تم استلام ${data.length} مهارة من الخادم');
        if (data.isNotEmpty) {
          print('نموذج للمهارة الأولى: ${data[0]}');
        }
        _Skills = data;
        return data;
      } else {
        print(
            'خطأ في استجابة الخادم: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print("خطأ في تحميل المهارات: $e");
      return [];
    }
  }

  // دالة للحصول على جميع الولايات
  Future<List<dynamic>> getWilayas() async {
    try {
      print("بدء تحميل الولايات...");
      final response =
          await http.get(Uri.parse('$baseUrl/api/Wilayas/GetAllWilayas'));
      print('استجابة الخادم للولايات: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('تم استلام ${data.length} ولاية من الخادم');
        if (data.isNotEmpty) {
          print('نموذج للولاية الأولى: ${data[0]}');
        }
        return data;
      } else {
        print(
            'خطأ في استجابة الخادم: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print("خطأ في تحميل الولايات: $e");
      return [];
    }
  }

  Future<http.Response> addJob(Map<String, dynamic> jobData) async {
    final url = '$baseUrl/api/Jobs/AddJob';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(jobData),
    );
    return response;
  }
}
