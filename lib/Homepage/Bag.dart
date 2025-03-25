import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Bag extends StatefulWidget {
  const Bag({super.key});

  @override
  State<Bag> createState() => _BagState();
}

class _BagState extends State<Bag> {
  // بيانات المحفظة
  double _balance = 25000.0;
  final List<Map<String, dynamic>> _transactions = [
    {
      "id": "TX123456",
      "title": "استلام راتب",
      "amount": 100000.0,
      "date": "15 يوليو 2023",
      "type": "income",
      "status": "completed",
      "icon": Icons.account_balance,
    },
    {
      "id": "TX123457",
      "title": "سحب نقدي",
      "amount": 15000.0,
      "date": "20 يوليو 2023",
      "type": "expense",
      "status": "completed",
      "icon": Icons.money,
    },
    {
      "id": "TX123458",
      "title": "دفع اشتراك",
      "amount": 5000.0,
      "date": "25 يوليو 2023",
      "type": "expense",
      "status": "completed",
      "icon": Icons.subscriptions,
    },
    {
      "id": "TX123459",
      "title": "تحويل إلى حساب",
      "amount": 30000.0,
      "date": "01 أغسطس 2023",
      "type": "expense",
      "status": "pending",
      "icon": Icons.send,
    },
    {
      "id": "TX123460",
      "title": "استلام مكافأة",
      "amount": 20000.0,
      "date": "05 أغسطس 2023",
      "type": "income",
      "status": "completed",
      "icon": Icons.card_giftcard,
    },
  ];

  final List<Map<String, dynamic>> _cards = [
    {
      "number": "**** **** **** 1234",
      "type": "Visa",
      "holder": "محمد أحمد",
      "expiry": "12/25",
      "color": const Color(0xFF36305E),
    },
    {
      "number": "**** **** **** 5678",
      "type": "MasterCard",
      "holder": "محمد أحمد",
      "expiry": "09/24",
      "color": const Color(0xFF8A70D6),
    },
  ];

  int _selectedCardIndex = 0;
  bool _showAllTransactions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: const Text(
          "المحفظة",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقات الائتمان
            Container(
              height: 220,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                onPageChanged: (index) {
                  setState(() {
                    _selectedCardIndex = index;
                  });
                },
                itemCount: _cards.length + 1, // +1 للبطاقة الإضافية
                itemBuilder: (context, index) {
                  if (index == _cards.length) {
                    return _buildAddCardWidget();
                  }
                  return _buildCreditCard(_cards[index], index);
                },
              ),
            ),

            // مؤشرات البطاقات
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_cards.length + 1, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedCardIndex == index
                        ? const Color(0xFF36305E)
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // الرصيد والأزرار
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "الرصيد المتاح",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${_balance.toStringAsFixed(2)} دج",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF36305E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        Icons.add,
                        "إيداع",
                        () => _showDepositDialog(),
                      ),
                      _buildActionButton(
                        Icons.send,
                        "تحويل",
                        () => _showTransferDialog(),
                      ),
                      _buildActionButton(
                        Icons.qr_code_scanner,
                        "مسح",
                        () {},
                      ),
                      _buildActionButton(
                        Icons.more_horiz,
                        "المزيد",
                        () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // المعاملات الأخيرة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "المعاملات الأخيرة",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF36305E),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllTransactions = !_showAllTransactions;
                      });
                    },
                    child: Text(
                      _showAllTransactions ? "عرض أقل" : "عرض الكل",
                      style: const TextStyle(
                        color: Color(0xFF8A70D6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // قائمة المعاملات
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _showAllTransactions
                  ? _transactions.length
                  : _transactions.length > 3
                      ? 3
                      : _transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(_transactions[index]);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // بناء بطاقة ائتمان
  Widget _buildCreditCard(Map<String, dynamic> card, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: card["color"],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // تصميم البطاقة
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              card["type"],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 20,
            child: Text(
              card["number"],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "صاحب البطاقة",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  card["holder"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "تاريخ الانتهاء",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  card["expiry"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // زر الخيارات
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              onPressed: () {
                _showCardOptionsBottomSheet(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة إضافة بطاقة جديدة
  Widget _buildAddCardWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8A70D6),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEBFF),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF8A70D6),
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "إضافة بطاقة جديدة",
              style: TextStyle(
                color: Color(0xFF8A70D6),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء زر إجراء
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEBFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8A70D6),
              size: 25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF36305E),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // بناء عنصر معاملة
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final bool isIncome = transaction["type"] == "income";
    final bool isPending = transaction["status"] == "pending";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة المعاملة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transaction["icon"],
              color: isIncome ? Colors.green : Colors.red,
              size: 25,
            ),
          ),
          const SizedBox(width: 15),
          // تفاصيل المعاملة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF36305E),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transaction["date"],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // مبلغ المعاملة
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isIncome ? "+" : "-"} ${transaction["amount"].toStringAsFixed(2)} دج",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 5),
              if (isPending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "قيد الانتظار",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // عرض خيارات البطاقة
  void _showCardOptionsBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: Color(0xFF8A70D6)),
                title: const Text("عرض تفاصيل البطاقة"),
                onTap: () {
                  Navigator.pop(context);
                  _showCardDetailsDialog(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF8A70D6)),
                title: const Text("تعديل البطاقة"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Color(0xFF8A70D6)),
                title: const Text("تجميد البطاقة"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "حذف البطاقة",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteCardDialog(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // عرض تفاصيل البطاقة
  void _showCardDetailsDialog(int index) {
    final card = _cards[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "تفاصيل البطاقة",
            style: TextStyle(
              color: Color(0xFF36305E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow("نوع البطاقة", card["type"]),
              _buildDetailRow("رقم البطاقة", card["number"]),
              _buildDetailRow("صاحب البطاقة", card["holder"]),
              _buildDetailRow("تاريخ الانتهاء", card["expiry"]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "إغلاق",
                style: TextStyle(color: Color(0xFF8A70D6)),
              ),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار حذف البطاقة
  void _showDeleteCardDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "حذف البطاقة",
            style: TextStyle(
              color: Color(0xFF36305E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "هل أنت متأكد من رغبتك في حذف هذه البطاقة؟ لا يمكن التراجع عن هذا الإجراء.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "إلغاء",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _cards.removeAt(index);
                  if (_selectedCardIndex >= _cards.length) {
                    _selectedCardIndex = _cards.length - 1;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text(
                "حذف",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار الإيداع
  void _showDepositDialog() {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "إيداع مبلغ",
            style: TextStyle(
              color: Color(0xFF36305E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: "المبلغ (دج)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "طريقة الإيداع",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "card",
                    child: Text("بطاقة ائتمان"),
                  ),
                  DropdownMenuItem(
                    value: "bank",
                    child: Text("تحويل بنكي"),
                  ),
                  DropdownMenuItem(
                    value: "cash",
                    child: Text("نقداً"),
                  ),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "إلغاء",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  final double amount = double.parse(amountController.text);
                  setState(() {
                    _balance += amount;
                    _transactions.insert(0, {
                      "id": "TX${DateTime.now().millisecondsSinceEpoch}",
                      "title": "إيداع مبلغ",
                      "amount": amount,
                      "date":
                          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                      "type": "income",
                      "status": "completed",
                      "icon": Icons.add_circle,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تم الإيداع بنجاح"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36305E),
              ),
              child: const Text(
                "إيداع",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار التحويل
  void _showTransferDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController accountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "تحويل مبلغ",
            style: TextStyle(
              color: Color(0xFF36305E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: accountController,
                decoration: const InputDecoration(
                  labelText: "رقم الحساب المستلم",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: "المبلغ (دج)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "البطاقة المستخدمة",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                items: _cards.map((card) {
                  return DropdownMenuItem<String>(
                    value: card["number"],
                    child: Text("${card["type"]} - ${card["number"]}"),
                  );
                }).toList(),
                onChanged: (value) {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "إلغاء",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isNotEmpty &&
                    accountController.text.isNotEmpty) {
                  final double amount = double.parse(amountController.text);
                  if (amount <= _balance) {
                    setState(() {
                      _balance -= amount;
                      _transactions.insert(0, {
                        "id": "TX${DateTime.now().millisecondsSinceEpoch}",
                        "title": "تحويل إلى حساب",
                        "amount": amount,
                        "date":
                            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                        "type": "expense",
                        "status": "pending",
                        "icon": Icons.send,
                      });
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تم إرسال طلب التحويل بنجاح"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("رصيد غير كافي"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36305E),
              ),
              child: const Text(
                "تحويل",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // بناء صف تفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF36305E),
            ),
          ),
        ],
      ),
    );
  }
}
