import 'package:flutter/material.dart';

import 'package:memoire/Homepage/OnboardingPage.dart';

import 'package:memoire/auth/GetstLogin.dart';

class Home2 extends StatefulWidget {
  const Home2({super.key});

  @override
  State<Home2> createState() => _Home2State();
}

class _Home2State extends State<Home2> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  List<Widget> _pages = [
    OnboardingPage(
      title: "Find your dream job easily with JobBit!",
      description:
          "Joßßit is the reference of IT recrutmenet in Algeria we help the candidates and the companies to find the perfect match",
      image: "images/Asset 1.png",
    ),
    OnboardingPage(
      title: "Explore Limitless Career Option Today!",
      description:
          "JoBBit is the reference of IT recrutmenet in Algeria we help the candidates and the companies to find the perfect matich",
      image: "images/Asset 2.png",
    ),
    OnboardingPage(
      title: "We help you find your job more easily!",
      description:
          "JaBBit is the reference of IT recrutmenet in Algeria, we help the candidates and the companies to find the perfect match",
      image: "images/Asset 4.png",
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, right: 20),
                child: TextButton(
                  onPressed: () {
                    // يمكنك إضافة الانتقال إلى الصفحة الرئيسية هنا
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 25,
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
          Expanded(
              child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: _pages,
          )),
          SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  width: _currentPage == index ? 20 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: _currentPage == index
                        ? Colors.purple
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8E49DE),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? " Get Started " : "Next",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
