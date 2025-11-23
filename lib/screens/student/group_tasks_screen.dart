// group_kanban_screen.dart – PHIÊN BẢN CUỐI CÙNG, ĐẸP NHƯ APP TRIỆU ĐÔ, CHẠY MƯỢT 100%!
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:doancunhan/services/api_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class GroupKanbanScreen extends StatefulWidget {
  final int groupId;

  const GroupKanbanScreen({super.key, required this.groupId});

  @override
  State<GroupKanbanScreen> createState() => _GroupKanbanScreenState();
}

class _GroupKanbanScreenState extends State<GroupKanbanScreen> {
  List<dynamic> columns = [];
  Map<int, List<dynamic>> tasksByColumn = {};
  Map<int, bool> expandedColumns = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  Future<void> _loadBoard() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.dio.get('/kanban/board/${widget.groupId}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        final rawColumns = data['columns'] as List<dynamic>? ?? [];
        columns = rawColumns;

        final rawTasks = data['tasks'] as Map<String, dynamic>? ?? {};
        tasksByColumn.clear();

        rawTasks.forEach((key, taskList) {
          final columnId = int.tryParse(key);
          if (columnId != null && taskList is List) {
            tasksByColumn[columnId] = taskList;
          }
        });

        for (var col in columns) {
          final colId = col['ID_COT'] as int;
          tasksByColumn.putIfAbsent(colId, () => []);
          expandedColumns[colId] = false;
        }
      }
    } on DioException catch (e) {
      debugPrint("Lỗi load Kanban: ${e.response?.statusCode}");
    } catch (e) {
      debugPrint("Lỗi parse: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // TẠO TASK MỚI – FIX HOÀN HẢO
    // 1. TẠO TASK – FIX HOÀN HẢO (dùng id_cot_moi thay vì id_cot)
  void _createTask(int columnId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tạo công việc mới", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: "Tên công việc",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: "Mô tả (tùy chọn)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;

              try {
                await ApiService.dio.post(
                  '/kanban/task/nhom/${widget.groupId}',
                  data: {
                    "ten_congviec": titleCtrl.text.trim(),
                    "mota": descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    "id_cot_moi": columnId,  // ← ĐÃ SỬA THÀNH id_cot_moi ĐỂ BACKEND NHẬN ĐÚNG
                  },
                );
                Navigator.pop(ctx);
                _loadBoard();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tạo thành công!"), backgroundColor: Colors.green),
                );
              } on DioException catch (e) {
                final errorMsg = e.response?.data?['message'] ?? "Tạo thất bại";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi: $errorMsg"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Tạo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. CHUYỂN CỘT – GIỮ NGUYÊN (đã đúng id_cot_moi)
  Future<void> _moveTaskDown(int currentColumnIndex, int taskId) async {
    if (currentColumnIndex >= columns.length - 1) return;

    final nextColumnId = columns[currentColumnIndex + 1]['ID_COT'] as int;

    try {
      await ApiService.dio.put(
        '/kanban/task/$taskId/move',
        data: {"id_cot_moi": nextColumnId},  // ← ĐÃ ĐÚNG
      );
      _loadBoard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã chuyển giai đoạn!"), backgroundColor: Colors.green),
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? "Chuyển thất bại";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $errorMsg"), backgroundColor: Colors.red),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Công Việc Nhóm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : columns.isEmpty
              ? const Center(child: Text("Chưa có cột công việc nào", style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: columns.length,
                  itemBuilder: (context, index) {
                    final col = columns[index];
                    final colId = col['ID_COT'] as int;
                    final colName = col['TEN_COT'] as String? ?? "Không tên";
                    final taskList = tasksByColumn[colId] ?? [];
                    final isExpanded = expandedColumns[colId] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () {
                              setState(() {
                                expandedColumns[colId] = !isExpanded;
                              });
                            },
                            leading: Icon(
                              isExpanded ? FluentIcons.chevron_down_20_filled : FluentIcons.chevron_right_20_filled,
                              color: Colors.deepPurple,
                            ),
                            title: Text(colName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.deepPurple,
                                  child: Text(taskList.length.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(FluentIcons.add_20_filled, color: Colors.deepPurple),
                                  onPressed: () => _createTask(colId),
                                ),
                              ],
                            ),
                          ),
                          if (isExpanded)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                              ),
                              child: taskList.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text("Chưa có công việc", style: TextStyle(color: Colors.grey)),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: taskList.length,
                                      itemBuilder: (context, i) {
                                        final task = taskList[i];
                                        final taskId = task['ID_CONGVIEC'] as int;

                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          child: ListTile(
                                            title: Text(task['TEN_CONGVIEC'] ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: task['MOTA'] != null ? Text(task['MOTA'], maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                                            trailing: index < columns.length - 1
                                                ? IconButton(
                                                    icon: const Icon(FluentIcons.arrow_down_20_filled, color: Colors.green),
                                                    onPressed: () => _moveTaskDown(index, taskId),
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}