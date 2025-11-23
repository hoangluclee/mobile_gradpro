// lib/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

 Future<void> _loadNotifications() async {
  setState(() => isLoading = true);

  try {
    final response = await ApiService.dio.get('/notifications');

    if (response.statusCode == 200) {
      final data = response.data;

      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'];
      }

      // ĐÃ SỬA: BỎ DẤU PHẨY THỪA
      setState(() {
        notifications = list;list;
        isLoading = false;
      });

      // Đánh dấu đã đọc
      try {
        await ApiService.dio.post('/notifications/mark-as-read');
      } catch (_) {}
    } else {
      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Lỗi tải thông báo: $e");
    if (mounted) {
      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  }
}

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Vừa xong";
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return "Vừa xong";
      if (diff.inHours < 1) return "${diff.inMinutes} phút trước";
      if (diff.inDays < 1) return "${diff.inHours} giờ trước";
      if (diff.inDays < 7) return "${diff.inDays} ngày trước";
      return DateFormat("dd/MM/yyyy HH:mm").format(dt);
    } catch (e) {
      return "Không rõ thời gian";
    }
  }

  IconData _getIcon(String? type) {
    if (type == null) return Icons.notifications;
    switch (type.toLowerCase()) {
      case 'meeting':
      case 'lichhop':
        return Icons.event_available;
      case 'topic':
      case 'detai':
        return Icons.assignment;
      case 'group':
      case 'nhom':
        return Icons.groups;
      case 'submission':
      case 'nopbai':
        return Icons.upload_file;
      case 'grading':
      case 'chamdiem':
        return Icons.rate_review;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    if (type == null) return Colors.grey;
    switch (type.toLowerCase()) {
      case 'meeting':
      case 'lichhop':
        return Colors.blue;
      case 'topic':
      case 'detai':
        return Colors.indigo;
      case 'group':
      case 'nhom':
        return Colors.green;
      case 'submission':
      case 'nopbai':
        return Colors.orange;
      case 'grading':
      case 'chamdiem':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Thông báo",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                // Nếu backend có route xóa hết thì gọi, không thì xóa local
                try {
                  await ApiService.dio.post('/notifications/clear-all');
                } catch (_) {}
                setState(() => notifications.clear());
              },
              child: const Text("Xóa hết", style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Chưa có thông báo nào",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Các thông báo sẽ xuất hiện ở đây",
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: Colors.deepPurple,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: notifications.length,
                    itemBuilder: (context, i) {
                      final n = notifications[i];

                      // Xử lý dữ liệu an toàn
                      final String title = n['title']?.toString() ??
                          n['data']?['title']?.toString() ??
                          "Thông báo mới";

                      final String body = n['body']?.toString() ??
                          n['data']?['body']?.toString() ??
                          "Bạn có thông báo mới từ hệ thống";

                      final String time = _formatTime(n['created_at']?.toString());

                      final String type = n['type']?.toString() ??
                          n['data']?['type']?.toString() ??
                          "general";

                      final bool isRead = n['read_at'] != null;

                      return Card(
                        elevation: isRead ? 2 : 8,
                        color: isRead ? Colors.white : Colors.deepPurple.withOpacity(0.07),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getIconColor(type).withOpacity(isRead ? 0.15 : 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIcon(type),
                              color: _getIconColor(type),
                              size: 28,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16.5,
                              color: isRead ? Colors.black87 : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                body,
                                style: const TextStyle(fontSize: 14.5, height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (!isRead) {
                              try {
                                await ApiService.dio.post('/notifications/mark-as-read');
                              } catch (_) {}
                              setState(() {
                                n['read_at'] = DateTime.now().toIso8601String();
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}