import 'dart:async'; // Import for TimeoutException
import 'dart:convert';
import 'dart:math'; // Keep if needed elsewhere, otherwise remove.

import 'package:http/http.dart' as http;

class ApiServers {
  // عنوان API الأساسي - يجب تحديثه عند تغير عنوان ngrok
  // قم بتحديث هذا العنوان عند تغير عنوان ngrok
  // يرجى تحديث هذا العنوان بعنوان ngrok الجديد
  static const String baseUrl = "https://b5b9-105-235-132-187.ngrok-free.app";

  // مهلة الاتصال بالخادم (بالثواني)
  static const int connectionTimeout = 30; // 30 ثانية

  // العناوين الفرعية تستخدم baseUrl لضمان التناسق
  String get basewilaya => "$baseUrl/api/Wilayas/GetWilayaByID/:WilayaID";
  String get baseSkills => "$baseUrl/api/Skills/GetSkillByID/:SkillID";
  String get allWilayasUrl => "$baseUrl/api/Wilayas/GetAllWilayas";

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

    // ✅ إرسال المهارات بشكل صحيح
    for (int i = 0; i < skills.length; i++) {
      request.fields['SkillIDs[$i]'] = skills[i].toString();
    }
    print("Sending skills: ${skills.join(',')}");

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
      // ... (rest of the logging remains the same)
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
      // ... (rest of the logging remains the same)
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
        return []; // Return empty list on error
      }
    } catch (e) {
      print("خطأ في تحميل المهارات: $e");
      return []; // Return empty list on exception
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
        return []; // Return empty list on error
      }
    } catch (e) {
      print("خطأ في تحميل الولايات: $e");
      return []; // Return empty list on exception
    }
  }

  Future<http.Response> addJob(Map<String, dynamic> jobData) async {
    final url = '$baseUrl/api/Jobs/AddJob';
    print('إضافة وظيفة جديدة إلى: $url');
    print('بيانات الوظيفة: ${jsonEncode(jobData)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(jobData),
      );

      print('استجابة إضافة وظيفة: ${response.statusCode}');
      print('محتوى الاستجابة: ${response.body}');

      // في حالة الخطأ 400، حاول تحليل رسالة الخطأ
      if (response.statusCode == 400) {
        try {
          final errorData = json.decode(response.body);
          print('تفاصيل الخطأ: $errorData');

          // التحقق من وجود رسائل خطأ محددة
          if (errorData is Map && errorData.containsKey('errors')) {
            print('أخطاء التحقق: ${errorData['errors']}');
          }
        } catch (e) {
          print('خطأ في تحليل استجابة الخطأ: $e');
        }
      }

      return response;
    } catch (e) {
      print('خطأ أثناء إضافة وظيفة: $e');
      throw Exception('فشل في إضافة وظيفة: $e');
    }
  }

  Future<http.Response> updateJob(
      int jobId, Map<String, dynamic> jobData) async {
    final url = Uri.parse('$baseUrl/api/Jobs/UpdateJob/$jobId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jobData),
      );
      print('Update Job Status Code: ${response.statusCode}');
      print('Update Job Response Body: ${response.body}');
      return response;
    } catch (e) {
      print('Error updating job: $e');
      throw Exception('Failed to update job: $e');
    }
  }

  Future<http.Response> getJobTypes() async {
    final url = "$baseUrl/api/jobs/GetAllJopTypes";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response;
    } else {
      print('Failed to load job types: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
          'Failed to load job types with status code: ${response.statusCode}');
    }
  }

  Future<http.Response> getExperienceLevels() async {
    final url = "$baseUrl/api/jobs/GetAllJobExperience";
    print('Fetching experience levels from: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Experience levels response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return response;
      } else {
        print('Failed to load experience levels: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Failed to load experience levels with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching experience levels: $e');
      throw Exception('Error fetching experience levels: $e');
    }
  }

  Future<http.Response> getJobsForCompany(int companyId) async {
    final url = "$baseUrl/api/jobs/GetAllJobsForCompany/$companyId";
    print('Fetching jobs for company $companyId from: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Get jobs for company response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error fetching jobs for company $companyId: $e');
      throw Exception('Error fetching jobs for company $companyId: $e');
    }
  }

  Future<http.Response> getCompaneID(int CompaneID) async {
    final url = "$baseUrl/api/Companies/GetCompanyByID/$CompaneID";
    print('Fetching company data for company $CompaneID from: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Get company data response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error fetching company data: $e');
      rethrow;
    }
  }

  Future<http.Response> GetAllApplicantsForCompanyJob(int CompaneID) async {
    final url =
        "$baseUrl/api/Companies/GetAllApplicantsForCompanyJob/$CompaneID";
    print('Fetching applicants for company $CompaneID from: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('Get applicants response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error fetching applicants for company $CompaneID: $e');
      throw Exception('Error fetching applicants for company $CompaneID: $e');
    }
  }

  Future<http.Response> FilterJobs({
    List<int?>? wilayaIDs,
    List<int?>? skillIDs,
    List<int?>? jobTypeIDs,
    List<int?>? jobExperienceIDs,
  }) async {
    final url = "$baseUrl/api/jobs/FilterJobs";
    print('Fetching filtered jobs from: $url');
    final Map<String, dynamic> requestBody = {
      if (wilayaIDs != null && wilayaIDs.any((id) => id != null))
        "WilayaIDs": wilayaIDs.where((id) => id != null).toList(),
      if (skillIDs != null && skillIDs.any((id) => id != null))
        "SkillIDs": skillIDs.where((id) => id != null).toList(),
      if (jobTypeIDs != null && jobTypeIDs.any((id) => id != null))
        "JobTypeIDs": jobTypeIDs.where((id) => id != null).toList(),
      if (jobExperienceIDs != null && jobExperienceIDs.any((id) => id != null))
        "JobExperienceIDs": jobExperienceIDs.where((id) => id != null).toList(),
    };
    print('Filter parameters: ${jsonEncode(requestBody)}');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      print('Filter jobs response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error filtering jobs: $e');
      throw Exception('Error filtering jobs: $e');
    }
  }

  Future<http.Response> getAllJobs() async {
    // This seems redundant now with GetAllAvailableJobs and FilterJobs.
    // Consider removing or clarifying its purpose.
    // For now, it calls FilterJobs without filters.
    return FilterJobs();
  }

  Future<http.Response> GetAllJobs() async {
    // This name is confusingly similar to getAllJobs.
    // Renaming to GetAllAvailableJobs for clarity might be good.
    final url = "$baseUrl/api/jobs/GetAllAvailableJobs";
    print('جلب جميع الوظائف المتاحة من: $url');
    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Connection'] = 'keep-alive';
        request.headers['Accept'] = 'application/json';
        final streamedResponse = await client
            .send(request)
            .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
          client.close();
          throw TimeoutException(
              'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
        });
        final response = await http.Response.fromStream(streamedResponse);
        print('استجابة جلب جميع الوظائف: ${response.statusCode}');
        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('خطأ أثناء جلب جميع الوظائف: $e');
      // Rethrow specific exceptions for better handling in UI
      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow; // Rethrow the specific timeout exception
      }
      throw Exception('حدث خطأ أثناء جلب جميع الوظائف: $e');
    }
  }

  // دالة للبحث عن وظائف بالنص - معدلة لإرجاع قائمة فارغة عند 404 وعدم استخدام بيانات وهمية
  Future<http.Response> searchJobs(String query) async {
    // Encode the query parameter to handle special characters safely in the URL
    final encodedQuery = Uri.encodeComponent(query);
    final url = "$baseUrl/api/jobs/FilterJobsByJobTitle/$encodedQuery";
    print('البحث عن وظائف من: $url');

    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Accept'] = 'application/json';

        print('البحث عن وظائف بالعنوان: $query');

        final streamedResponse = await client
            .send(request)
            .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
          client.close();
          throw TimeoutException(// Throw specific TimeoutException
              'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
        });

        final response = await http.Response.fromStream(streamedResponse);
        print('استجابة البحث عن وظائف: ${response.statusCode}');

        // If 404 Not Found, return a response with an empty JSON array '[]' and status 200
        // This allows the UI to correctly interpret it as "no results found"
        if (response.statusCode == 404) {
          print(
              'لم يتم العثور على وظائف مطابقة للبحث (404). Returning empty list.');
          return http.Response('[]', 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }

        // For successful responses (200), print details but return the original response
        if (response.statusCode == 200) {
          try {
            // Attempt to decode to verify it's valid JSON and log details
            final jsonResponse = json.decode(response.body);
            if (jsonResponse is List) {
              print('تم العثور على ${jsonResponse.length} وظيفة');
              // Optional: Log details of found jobs for debugging
              // for (var job in jsonResponse) {
              //   print('--- Job Title: ${job['title']}');
              // }
            } else {
              print('الاستجابة ليست قائمة JSON.');
              // Even if not a list, return the original response for the caller to handle
            }
          } catch (e) {
            print(
                'خطأ في تحليل استجابة JSON: $e. Returning original response.');
            // Return original response even if JSON parsing fails here
          }
        }

        // Return the original response for status codes other than 404
        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('خطأ أثناء البحث عن وظائف: $e');

      // Rethrow specific exceptions for better handling in UI
      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow; // Rethrow the specific timeout exception
      }

      // For other errors, throw a generic exception
      throw Exception('حدث خطأ أثناء البحث عن وظائف: $e');
      // DO NOT return mock data: return http.Response('[]', 500); // Or throw
    }
  }

  // دالة لجلب جميع الوظائف المتاحة للمبرمجين (مكررة؟)
  // Consider removing this if it's identical to the other FilterJobs
  Future<http.Response> filterJobs({
    List<int?>? wilayaIDs,
    List<int?>? skillIDs,
    List<int?>? jobTypeIDs,
    List<int?>? jobExperienceIDs,
  }) async {
    final url = "$baseUrl/api/jobs/FilterJobs";
    print('Fetching filtered jobs from: $url');
    final Map<String, dynamic> requestBody = {
      if (wilayaIDs != null && wilayaIDs.any((id) => id != null))
        "WilayaIDs": wilayaIDs.where((id) => id != null).toList(),
      if (skillIDs != null && skillIDs.any((id) => id != null))
        "SkillIDs": skillIDs.where((id) => id != null).toList(),
      if (jobTypeIDs != null && jobTypeIDs.any((id) => id != null))
        "JobTypeIDs": jobTypeIDs.where((id) => id != null).toList(),
      if (jobExperienceIDs != null && jobExperienceIDs.any((id) => id != null))
        "JobExperienceIDs": jobExperienceIDs.where((id) => id != null).toList(),
    };
    print('Filter parameters: ${jsonEncode(requestBody)}');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      print('Filter jobs response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error filtering jobs: $e');
      throw Exception('Error filtering jobs: $e');
    }
  }

  // دالة لجلب جميع الوظائف المتاحة للمبرمجين (مكررة؟)
  // Consider removing this if it's identical to GetAllJobs
  Future<http.Response> getAllAvailableJobs() async {
    final url = "$baseUrl/api/jobs/GetAllAvailableJobs";
    print('Fetching all available jobs from: $url');
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
        throw TimeoutException(
            'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
      });
      print('Get all available jobs response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Error fetching all available jobs: $e');
      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Error fetching all available jobs: $e');
    }
  }

  Future<http.Response> GetJobSeekerByID(int JobSeekerID) async {
    final url = "$baseUrl/api/JobSeekers/GetJobSeekerByID/$JobSeekerID";
    print('جلب بيانات الباحث عن عمل من: $url');
    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Connection'] = 'keep-alive';
        request.headers['Accept'] = 'application/json';
        final streamedResponse = await client
            .send(request)
            .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
          client.close();
          throw TimeoutException(
              'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
        });
        final response = await http.Response.fromStream(streamedResponse);
        print('استجابة جلب بيانات الباحث عن عمل: ${response.statusCode}');
        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('خطأ أثناء جلب بيانات الباحث عن عمل: $e');
      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('حدث خطأ أثناء جلب بيانات الباحث عن عمل: $e');
    }
  }

  Future<http.Response> applyForJob({
    required int jobID,
    required int jobSeekerID,
  }) async {
    final url =
        "$baseUrl/api/jobs/ApplayForJob"; // Check if this endpoint is correct
    print('تقديم طلب وظيفة إلى: $url');
    try {
      final client = http.Client();
      try {
        final Map<String, dynamic> requestBody = {
          'jobID': jobID,
          'jobSeekerID': jobSeekerID,
        };
        final request = http.Request('POST', Uri.parse(url));
        request.headers['Content-Type'] = 'application/json';
        request.headers['Accept'] =
            'text/plain'; // Or 'application/json' depending on API
        request.body = jsonEncode(requestBody);

        final streamedResponse = await client
            .send(request)
            .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
          client.close();
          throw TimeoutException(
              'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
        });

        final response = await http.Response.fromStream(streamedResponse);
        print('استجابة تقديم طلب وظيفة: ${response.statusCode}');

        // Handle specific errors like 503 or 400 if needed, potentially with retries or alternative paths
        if (response.statusCode == 503) {
          print('الخادم غير متاح حاليًا (503).');
          // Consider adding retry logic here if appropriate
          throw Exception('الخادم غير متاح مؤقتاً (503).');
        }
        if (response.statusCode == 400) {
          print('خطأ في الطلب (400): ${response.body}');
          // Check for ngrok HTML response
          if (response.body.contains('ngrok') ||
              response.body.contains('<!DOCTYPE html>')) {
            throw Exception(
                'فشل الطلب بسبب مشكلة في ngrok (قد يكون العنوان تغير أو انتهت صلاحيته).');
          }
          throw Exception('فشل تقديم الطلب (400): ${response.body}');
        }

        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('خطأ أثناء تقديم طلب وظيفة: $e');
      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('حدث خطأ أثناء تقديم طلب وظيفة: $e');
    }
  }

  // دالة لجلب طلبات التوظيف الخاصة بالباحث عن عمل
  Future<http.Response> getJobSeekerApplications(int jobSeekerID) async {
    final url =
        "$baseUrl/api/JobSeekers/GetAllJobSeekerApplications/$jobSeekerID";
    print('جلب طلبات التوظيف للباحث عن عمل من: $url');

    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Accept'] = 'application/json';

        final streamedResponse = await client
            .send(request)
            .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
          client.close();
          throw TimeoutException(
              'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
        });

        final response = await http.Response.fromStream(streamedResponse);
        print('استجابة جلب طلبات التوظيف: ${response.statusCode}');

        // معالجة حالات الخطأ المختلفة
        if (response.statusCode == 404) {
          print('لم يتم العثور على طلبات توظيف لهذا المستخدم');
          // إرجاع قائمة فارغة بدلاً من رمي استثناء
          return http.Response('[]', 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }

        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('خطأ أثناء جلب طلبات التوظيف: $e');

      // معالجة أنواع الأخطاء المختلفة
      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow; // إعادة رمي استثناء انتهاء المهلة
      }

      // إرجاع قائمة فارغة في حالة حدوث خطأ آخر
      return http.Response('[]', 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }
  }

  Future<http.Response> getRequestByID(int requestID) async {
    final url = "$baseUrl/api/Requests/GetRequestByID/$requestID";
    print('جلب طلب توظيف بالمعرف: $url');

    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        request.headers['Accept'] = 'application/json';

        final streamedResponse = await client
            .send(request)
            .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
          client.close();
          throw TimeoutException(
              'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
        });

        final response = await http.Response.fromStream(streamedResponse);
        print('استجابة جلب طلب توظيف: ${response.statusCode}');

        if (response.statusCode == 404) {
          print('لم يتم العثور على طلب توظيف بهذا المعرف');
          throw Exception('لم يتم العثور على طلب توظيف بهذا المعرف');
        }

        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('خطأ أثناء جلب طلب التوظيف: $e');

      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow; // إعادة رمي استثناء انتهاء المهلة
      }

      throw Exception('فشل في جلب طلب التوظيف: $e');
    }
  }

  // تحديث حالة طلب التوظيف
  Future<http.Response> updateRequestStatus(
      int requestID, bool newStatus) async {
    final url =
        "$baseUrl/api/jobs/UpdateStatusRequestJob/$requestID,$newStatus";
    print('تحديث حالة طلب التوظيف: $url');

    try {
      final client = http.Client();
      try {
        final request = http.Request('PUT', Uri.parse(url));
        request.headers['Accept'] = 'application/json';

        final streamedResponse = await client
            .send(request)
            .timeout(Duration(seconds: connectionTimeout), onTimeout: () {
          client.close();
          throw TimeoutException(
              'انتهت مهلة الاتصال بالخادم. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
        });

        final response = await http.Response.fromStream(streamedResponse);
        print('استجابة تحديث حالة طلب التوظيف: ${response.statusCode}');

        if (response.statusCode == 404) {
          print('لم يتم العثور على طلب توظيف بهذا المعرف');
          throw Exception('لم يتم العثور على طلب توظيف بهذا المعرف');
        }

        return response;
      } finally {
        client.close();
      }
    } catch (e) {
      print('خطأ أثناء تحديث حالة طلب التوظيف: $e');

      if (e.toString().contains('ngrok')) {
        throw Exception(
            'يبدو أن عنوان الخادم (ngrok) قد تغير. يرجى تحديث عنوان API في التطبيق.');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection failed')) {
        throw Exception(
            'تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت وأن الخادم يعمل بشكل صحيح.');
      } else if (e is TimeoutException) {
        rethrow; // إعادة رمي استثناء انتهاء المهلة
      }

      throw Exception('فشل في تحديث حالة طلب التوظيف: $e');
    }
  }
}
