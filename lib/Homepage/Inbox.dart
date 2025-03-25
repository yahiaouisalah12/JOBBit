import 'package:flutter/material.dart';

class Inbox extends StatefulWidget {
  const Inbox({super.key});

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> _messages = [
    {
      "name": "شركة تكنولوجيا المعلومات",
      "avatar": "TI",
      "message":
          "مرحباً، نود إبلاغك بأنك تم اختيارك للمقابلة الشخصية لوظيفة مطور واجهة أمامية",
      "time": "10:30 ص",
      "date": "اليوم",
      "unread": true,
    },
    {
      "name": "استوديو التصميم",
      "avatar": "AD",
      "message":
          "شكراً لتقديمك على وظيفة مصمم UI/UX، سنراجع سيرتك الذاتية ونرد عليك قريباً",
      "time": "أمس",
      "date": "12:45 م",
      "unread": true,
    },
    {
      "name": "شركة البرمجيات",
      "avatar": "SP",
      "message": "تم قبول طلبك للوظيفة! نرجو الرد لتحديد موعد بدء العمل",
      "time": "الأربعاء",
      "date": "09:15 ص",
      "unread": false,
    },
    {
      "name": "مؤسسة التقنية",
      "avatar": "MT",
      "message":
          "هل أنت متاح للعمل على مشروع بدوام جزئي؟ نحتاج مطور فلاتر لمدة 3 أشهر",
      "time": "الثلاثاء",
      "date": "14:20 م",
      "unread": false,
    },
    {
      "name": "شركة الاتصالات",
      "avatar": "ET",
      "message": "نشكرك على اهتمامك بالوظيفة، لكن تم اختيار مرشح آخر",
      "time": "23 يونيو",
      "date": "11:00 ص",
      "unread": false,
    },
  ];

  final List<Map<String, dynamic>> _notifications = [
    {
      "title": "تم قبول طلبك",
      "description":
          "تهانينا! تم قبول طلبك لوظيفة مطور واجهة أمامية في شركة تكنولوجيا المعلومات",
      "time": "منذ ساعتين",
      "icon": Icons.check_circle,
      "color": Colors.green,
    },
    {
      "title": "مقابلة جديدة",
      "description":
          "لديك مقابلة شخصية غداً الساعة 10:00 صباحاً مع شركة البرمجيات",
      "time": "منذ 5 ساعات",
      "icon": Icons.calendar_today,
      "color": Colors.blue,
    },
    {
      "title": "تم مشاهدة سيرتك الذاتية",
      "description": "قامت 3 شركات بمشاهدة سيرتك الذاتية في الأسبوع الماضي",
      "time": "منذ يومين",
      "icon": Icons.visibility,
      "color": Colors.purple,
    },
    {
      "title": "وظائف مقترحة",
      "description": "هناك 5 وظائف جديدة تتناسب مع مهاراتك، تصفحها الآن",
      "time": "منذ 3 أيام",
      "icon": Icons.work,
      "color": Colors.orange,
    },
    {
      "title": "تحديث النظام",
      "description": "تم تحديث النظام بميزات جديدة، اكتشفها الآن",
      "time": "منذ أسبوع",
      "icon": Icons.system_update,
      "color": Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: const Text(
          "الرسائل والإشعارات",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "الرسائل"),
            Tab(text: "الإشعارات"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // البحث في الرسائل
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // علامة التبويب الأولى: الرسائل
          _buildMessagesTab(),

          // علامة التبويب الثانية: الإشعارات
          _buildNotificationsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF36305E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // إنشاء رسالة جديدة
          _showNewMessageDialog();
        },
      ),
    );
  }

  // بناء علامة تبويب الرسائل
  Widget _buildMessagesTab() {
    return _messages.isEmpty
        ? _buildEmptyState(
            "لا توجد رسائل",
            "ستظهر هنا الرسائل الواردة من الشركات والمستخدمين",
            Icons.message,
          )
        : ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageItem(message);
            },
          );
  }

  // بناء علامة تبويب الإشعارات
  Widget _buildNotificationsTab() {
    return _notifications.isEmpty
        ? _buildEmptyState(
            "لا توجد إشعارات",
            "ستظهر هنا الإشعارات الجديدة",
            Icons.notifications,
          )
        : ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationItem(notification);
            },
          );
  }

  // بناء عنصر رسالة
  Widget _buildMessageItem(Map<String, dynamic> message) {
    return InkWell(
      onTap: () {
        // فتح محادثة
        _openConversation(message);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message["unread"] ? const Color(0xFFEFEBFF) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المرسل
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF8A70D6),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  message["avatar"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // محتوى الرسالة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        message["name"],
                        style: TextStyle(
                          fontWeight: message["unread"]
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                          color: const Color(0xFF36305E),
                        ),
                      ),
                      Text(
                        message["time"],
                        style: TextStyle(
                          color: message["unread"]
                              ? const Color(0xFF8A70D6)
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message["message"],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: message["unread"]
                          ? Colors.black87
                          : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message["date"],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء عنصر إشعار
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أيقونة الإشعار
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: notification["color"].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              notification["icon"],
              color: notification["color"],
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          // محتوى الإشعار
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification["title"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF36305E),
                      ),
                    ),
                    Text(
                      notification["time"],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification["description"],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء حالة فارغة
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // فتح محادثة
  void _openConversation(Map<String, dynamic> message) {
    // تحديث حالة القراءة
    setState(() {
      message["unread"] = false;
    });

    // انتقال إلى صفحة المحادثة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ConversationScreen(
          name: message["name"],
          avatar: message["avatar"],
        ),
      ),
    );
  }

  // عرض مربع حوار رسالة جديدة
  void _showNewMessageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "رسالة جديدة",
            style: TextStyle(
              color: Color(0xFF36305E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "المستلم",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: const InputDecoration(
                  labelText: "الموضوع",
                  prefixIcon: Icon(Icons.subject),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "الرسالة",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
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
                // إرسال الرسالة
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("تم إرسال الرسالة بنجاح"),
                    backgroundColor: Color(0xFF36305E),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36305E),
              ),
              child: const Text(
                "إرسال",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// صفحة المحادثة
class _ConversationScreen extends StatefulWidget {
  final String name;
  final String avatar;

  const _ConversationScreen({
    required this.name,
    required this.avatar,
  });

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [
    {
      "text":
          "مرحباً، نود إبلاغك بأنك تم اختيارك للمقابلة الشخصية لوظيفة مطور واجهة أمامية",
      "isMe": false,
      "time": "10:30 ص",
    },
    {
      "text": "شكراً جزيلاً! متى ستكون المقابلة؟",
      "isMe": true,
      "time": "10:35 ص",
    },
    {
      "text":
          "المقابلة ستكون يوم الخميس القادم الساعة 11:00 صباحاً في مقر الشركة",
      "isMe": false,
      "time": "10:40 ص",
    },
    {
      "text": "هل يمكنك إرسال العنوان بالتفصيل؟",
      "isMe": true,
      "time": "10:42 ص",
    },
    {
      "text":
          "بالتأكيد، العنوان هو: شارع الاستقلال، بناية التكنولوجيا، الطابق الثالث، مكتب رقم 305",
      "isMe": false,
      "time": "10:45 ص",
    },
    {
      "text": "شكراً لك، سأكون هناك في الموعد المحدد",
      "isMe": true,
      "time": "10:50 ص",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36305E),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8A70D6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  widget.avatar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              // اتصال
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // المزيد من الخيارات
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // رسائل المحادثة
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                return _buildChatMessage(
                  message["text"],
                  message["isMe"],
                  message["time"],
                );
              },
            ),
          ),

          // مربع إدخال الرسالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFF8A70D6)),
                  onPressed: () {
                    // إرفاق ملف
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "اكتب رسالتك هنا...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF36305E)),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء فقاعة رسالة
  Widget _buildChatMessage(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF36305E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // إرسال رسالة جديدة
  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _chatMessages.add({
          "text": _messageController.text,
          "isMe": true,
          "time": "${DateTime.now().hour}:${DateTime.now().minute}",
        });
        _messageController.clear();
      });
    }
  }
}
