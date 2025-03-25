import 'package:flutter/material.dart';
import 'package:memoire/AddJob/AddJob.dart';
import 'package:memoire/Compane/HoneCompane.dart';

import 'package:memoire/Homepage/Home1.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // إزالة استخدام الخط المحلي مؤقتًا
          // fontFamily: 'Cairo',
          primaryColor: const Color(0xFF36305E),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF36305E),
            primary: const Color(0xFF36305E),
            secondary: const Color(0xFF8A70D6),
          ),
        ),
        home: Honecompane()
        //Addjob(companyID: 1), // تمرير قيمة لمعرف الشركة
        );
  }
}
