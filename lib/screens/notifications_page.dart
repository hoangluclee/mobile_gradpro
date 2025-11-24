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

        setState(() {
          notifications = list;
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
      case 'lich_hop':
        return Icons.event;
      case 'topic':
      case 'detai':
      case 'de_tai':
        return Icons.book;
      case 'group':
      case 'nhom':
      case 'join_request':
      case 'invitation':
        return Icons.group;
      case 'submission':
      case 'nopbai':
      case 'nop_bai':
        return Icons.upload_file;
      case 'grading':
      case 'chamdiem':
      case 'cham_diem':
        return Icons.rate_review;
      case 'system':
        return Icons.info;
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
      case 'join_request':
      case 'invitation':
        return Colors.green;
      case 'submission':
      case 'nopbai':
        return Colors.orange;
      case 'grading':
      case 'chamdiem':
        return Colors.purple;
      case 'system':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationTitle(Map<String, dynamic> n) {
    final data = n['data'] is Map ? n['data'] : {};
    if (data['title'] != null) return data['title'].toString();

    final type = (n['type'] ?? "").toString().toLowerCase();
    switch (type) {
      case 'join_request_received':
        return "Yêu cầu tham gia nhóm";
      case 'join_request_approved':
        return "Yêu cầu đã được duyệt";
      case 'join_request_rejected':
        return "Yêu cầu bị từ chối";
      case 'invitation_received':
        return "Lời mời vào nhóm";
      case 'invitation_accepted':
        return "Lời mời đã được chấp nhận";
      case 'invitation_rejected':
        return "Lời mời bị từ chối";
      case 'new_meeting':
        return "Lịch họp mới";
      case 'meeting_updated':
        return "Lịch họp đã cập nhật";
      case 'topic_registered':
        return "Đăng ký đề tài thành công";
      case 'topic_approved':
        return "Đề tài được duyệt";
      default:
        return "Thông báo mới";
    }
  }

  String _getNotificationBody(Map<String, dynamic> n) {
    final data = n['data'] is Map ? n['data'] : {};
    if (data['body'] != null) return data['body'].toString();
    if (data['message'] != null) return data['message'].toString();

    final type = (n['type'] ?? "").toString().toLowerCase();
    switch (type) {
      case 'join_request_received':
        return "Có thành viên mới muốn tham gia nhóm của bạn";
      case 'join_request_approved':
        return "Yêu cầu tham gia nhóm ${data['group_name'] ?? ""} đã được chấp nhận";
      case 'join_request_rejected':
        return "Yêu cầu tham gia nhóm ${data['group_name'] ?? ""} đã bị từ chối";
      case 'invitation_received':
        return "${data['requester_name'] ?? "Ai đó"} mời bạn vào nhóm ${data['group_name'] ?? ""}";
      case 'invitation_accepted':
        return "${data['member_name'] ?? "Thành viên"} đã tham gia nhóm";
      case 'invitation_rejected':
        return "${data['member_name'] ?? "Thành viên"} đã từ chối lời mời";
      case 'new_meeting':
        return "Cuộc họp mới: ${data['title'] ?? ""}";
      default:
        return "Bạn có thông báo mới từ hệ thống";
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
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 28),
            SizedBox(width: 10),
            Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
          ],
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
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
                        Icon(Icons.notifications_off, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        const Text("Chưa có thông báo nào", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text("Các thông báo sẽ xuất hiện ở đây", style: TextStyle(color: Colors.grey[600], fontSize: 15)),
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
                      final type = (n['type'] ?? "general").toString();
                      final isRead = n['read_at'] != null;

                      final title = _getNotificationTitle(n);
                      final body = _getNotificationBody(n);
                      final time = _formatTime(n['created_at']?.toString());

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
                            child: Icon(_getIcon(type), color: _getIconColor(type), size: 28),
                          ),
                          title: Text(title, style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 16.5)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(body, style: const TextStyle(fontSize: 14.5, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(time, style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
                                  if (!isRead)
                                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
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