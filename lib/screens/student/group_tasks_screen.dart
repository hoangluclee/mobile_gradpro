import 'package:flutter/material.dart';
import 'package:doancunhan/services/api_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';

class GroupKanbanScreen extends StatefulWidget {
  final int groupId;
  const GroupKanbanScreen({super.key, required this.groupId});

  @override
  State<GroupKanbanScreen> createState() => _GroupKanbanScreenState();
}

class _GroupKanbanScreenState extends State<GroupKanbanScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> columns = [];
  List<Map<String, dynamic>> members = [];
  Map<int, List<Map<String, dynamic>>> tasksByColumn = {};
  Map<int, bool> expandedColumns = {};

  bool isLoading = true;
  bool isListView = false;
  Set<int> filteredUserIds = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBoard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBoard() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.dio.get('/kanban/board/${widget.groupId}');
      if (response.statusCode == 200) {
        final data = response.data;

        setState(() {
          columns = (data['columns'] as List).cast<Map<String, dynamic>>()
            ..sort((a, b) => (a['THUTU_HIENTHI'] as int).compareTo(b['THUTU_HIENTHI'] as int));

          members = (data['members'] as List)
              .map((e) => e['nguoidung'] as Map<String, dynamic>)
              .toList();

          tasksByColumn.clear();
          final rawTasks = data['tasks'] as Map<String, dynamic>;
          rawTasks.forEach((key, value) {
            final colId = int.tryParse(key);
            if (colId != null && value is List) {
              tasksByColumn[colId] = value.cast<Map<String, dynamic>>();
            }
          });

          expandedColumns.clear();
          for (var col in columns) {
            final id = col['ID_COT'] as int;
            tasksByColumn.putIfAbsent(id, () => []);
            expandedColumns[id] = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải dữ liệu: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

 void _createTask(int columnId) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime? deadline;
  String priority = 'Trung bình';
  List<int> selectedAssignees = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, dialogSetState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          "Tạo công việc mới",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Tên công việc",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Mô tả (tùy chọn)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: InputDecoration(
                    labelText: "Độ ưu tiên",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Thấp', 'Trung bình', 'Cao']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => dialogSetState(() => priority = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  tileColor: Colors.grey[50],
                  title: Text(
                    deadline == null
                        ? "Chọn ngày hết hạn"
                        : "Hết hạn: ${DateFormat('dd/MM/yyyy').format(deadline!)}",
                    style: TextStyle(
                      color: deadline == null ? Colors.grey[600] : Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      dialogSetState(() => deadline = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text("Gán thành viên:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: members.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("Không có thành viên nào", style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: members.length,
                          itemBuilder: (_, i) {
                            final m = members[i];
                            final id = m['ID_NGUOIDUNG'] as int;
                            final name = m['HODEM_VA_TEN'] as String;
                            final isSelected = selectedAssignees.contains(id);

                            return CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              title: Text(name, style: const TextStyle(fontSize: 14.5)),
                              value: isSelected,
                              activeColor: Colors.deepPurple,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.deepPurple, width: 2),
                              onChanged: (v) {
                                dialogSetState(() {
                                  if (v == true) {
                                    selectedAssignees.add(id);
                                  } else {
                                    selectedAssignees.remove(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                if (selectedAssignees.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: selectedAssignees.map((id) {
                      final name = members.firstWhere((m) => m['ID_NGUOIDUNG'] == id)['HODEM_VA_TEN'];
                      return Chip(
                        label: Text(name, style: const TextStyle(fontSize: 13)),
                        backgroundColor: Colors.deepPurple.shade100,
                        deleteIconColor: Colors.deepPurple,
                        onDeleted: () {
                          dialogSetState(() => selectedAssignees.remove(id));
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập tên công việc!"), backgroundColor: Colors.orange),
                );
                return;
              }

              try {
                await ApiService.dio.post('/kanban/task/nhom/${widget.groupId}', data: {
                  "TEN_CONGVIEC": titleCtrl.text.trim(),
                  "MOTA": descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  "ID_COT": columnId,
                  "NGAY_HETHAN": deadline != null ? DateFormat('yyyy-MM-dd').format(deadline!) : null,
                  "DO_UUTIEN": priority,
                  "assignee_ids": selectedAssignees,
                });

                Navigator.pop(ctx);
                _loadBoard();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tạo thành công!"), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Tạo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}


void _showTaskDetail(Map<String, dynamic> task, int currentColId) async {
  final titleCtrl = TextEditingController(text: task['TEN_CONGVIEC'] ?? '');
  final descCtrl = TextEditingController(text: task['MOTA'] ?? '');
  DateTime? deadline = task['NGAY_HETHAN'] != null
      ? DateTime.tryParse(task['NGAY_HETHAN'])
      : null;
  String priority = task['DO_UUTIEN'] ?? 'Trung bình';
  List<int> selectedAssignees = (task['nguoi_duoc_phan_cong'] as List?)
          ?.map((e) => e['ID_NGUOIDUNG'] as int)
          .toList() ??
      [];

  final isLastColumn = columns.last['ID_COT'] == currentColId;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, dialogSetState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            
            const Icon(FluentIcons.clipboard_task_24_filled, color: Colors.deepPurple, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Chi tiết công việc",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
              ),
            ),
            if (isLastColumn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 6),
                    Text("Hoàn thành", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên công việc
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: "Tên công việc",
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mô tả
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Mô tả (tùy chọn)",
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Độ ưu tiên
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: InputDecoration(
                    labelText: "Độ ưu tiên",
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Thấp', 'Trung bình', 'Cao']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => dialogSetState(() => priority = v!),
                ),
                const SizedBox(height: 16),

                // Ngày hết hạn
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.deepPurple.shade200),
                  ),
                  tileColor: Colors.deepPurple.shade50,
                  leading: const Icon(Icons.calendar_today_rounded, color: Colors.deepPurple),
                  title: Text(
                    deadline == null
                        ? "Chưa đặt ngày hết hạn"
                        : "Hết hạn: ${DateFormat('dd/MM/yyyy').format(deadline!)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: deadline == null ? Colors.grey[700] : Colors.deepPurple.shade700,
                    ),
                  ),
                  trailing: deadline != null
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.red.shade600),
                          onPressed: () => dialogSetState(() => deadline = null),
                        )
                      : const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      dialogSetState(() => deadline = picked);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Thành viên được gán
                const Text("Thành viên được gán:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.deepPurple.shade50,
                  ),
                  child: members.isEmpty
                      ? const Center(child: Text("Không có thành viên trong nhóm", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: members.length,
                          itemBuilder: (_, i) {
                            final m = members[i];
                            final id = m['ID_NGUOIDUNG'] as int;
                            final name = m['HODEM_VA_TEN'] as String;
                            final isChecked = selectedAssignees.contains(id);

                            return CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              title: Text(name, style: const TextStyle(fontSize: 14.5)),
                              value: isChecked,
                              activeColor: Colors.deepPurple,
                              checkColor: Colors.white,
                              onChanged: (v) {
                                dialogSetState(() {
                                  if (v == true) {
                                    selectedAssignees.add(id);
                                  } else {
                                    selectedAssignees.remove(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),

                // Hiển thị chip thành viên đã chọn
                if (selectedAssignees.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedAssignees.map((id) {
                      final name = members.firstWhere(
                        (m) => m['ID_NGUOIDUNG'] == id,
                        orElse: () => {'HODEM_VA_TEN': 'Không rõ'},
                      )['HODEM_VA_TEN'];
                      return Chip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            name.toString().isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                        label: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        backgroundColor: Colors.deepPurple.shade100,
                        deleteIconColor: Colors.deepPurple.shade700,
                        onDeleted: () => dialogSetState(() => selectedAssignees.remove(id)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.close, color: Colors.grey),
            label: const Text("Đóng"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text("Lưu thay đổi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tên công việc không được để trống!"), backgroundColor: Colors.orange),
                );
                return;
              }

              try {
                await ApiService.dio.put('/kanban/task/${task['ID_CONGVIEC']}', data: {
                  "TEN_CONGVIEC": titleCtrl.text.trim(),
                  "MOTA": descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  "NGAY_HETHAN": deadline != null ? DateFormat('yyyy-MM-dd').format(deadline!) : null,
                  "DO_UUTIEN": priority,
                  "assignee_ids": selectedAssignees,
                });

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadBoard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi cập nhật: $e"), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

  void _moveToNextColumn(int taskId, int currentColId) async {
    final currentIndex =
        columns.indexWhere((c) => c['ID_COT'] == currentColId);
    if (currentIndex == -1 || currentIndex >= columns.length - 1) return;

    final nextCol = columns[currentIndex + 1];
    final nextColId = nextCol['ID_COT'] as int;
    final nextColName = nextCol['TEN_COT'] as String;

    try {
      await ApiService.dio.put('/kanban/task/$taskId/move',
          data: {"ID_COT_MOI": nextColId, "THUTU_MOI": 9999});
      _loadBoard();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã chuyển sang "$nextColName"'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi chuyển: $e"), backgroundColor: Colors.red));
    }
  }

  Color _getPriorityColor(String? p) {
    return switch (p) {
      'Cao' => Colors.red.shade600,
      'Trung bình' => Colors.orange.shade700,
      'Thấp' => Colors.green.shade600,
      _ => Colors.grey,
    };
  }

  Widget _buildAssigneesAvatars(List<Map<String, dynamic>> assignees) {
    if (assignees.isEmpty) return const SizedBox();
    return SizedBox(
      width: 70,
      height: 30,
      child: Stack(
        children: assignees.take(4).map((e) {
          final index = assignees.indexOf(e);
          return Transform.translate(
            offset: Offset(index * 18.0, 0),
            child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.deepPurple,
                child: Text(e['HODEM_VA_TEN'].toString()[0].toUpperCase(),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white))),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.deepPurple.withOpacity(0.5),
        title: const Text("Bảng Kanban Nhóm",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(isListView
                  ? FluentIcons.board_24_filled
                  : FluentIcons.list_24_filled),
              onPressed: () => setState(() => isListView = !isListView)),
          IconButton(onPressed: _loadBoard, icon: const Icon(Icons.refresh_rounded)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (i) => setState(() => isListView = i == 1),
          tabs: const [
            Tab(icon: Icon(FluentIcons.board_24_regular), text: "Kanban"),
            Tab(icon: Icon(FluentIcons.list_24_regular), text: "Danh sách"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : IndexedStack(
              index: isListView ? 1 : 0,
              children: [
                // ==================== KANBAN VIEW  ====================
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: columns.length,
                  itemBuilder: (_, index) {
                    final col = columns[index];
                    final colId = col['ID_COT'] as int;
                    final colName = col['TEN_COT'] as String;
                    final tasks = tasksByColumn[colId] ?? [];
                    final isExpanded = expandedColumns[colId] ?? true;
                    final isLastColumn = index == columns.length - 1;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isExpanded ? 0.15 : 0.08),
                            blurRadius: isExpanded ? 20 : 12,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            // Header – bấm để mở/thu gọn
                            InkWell(
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(20),
                                bottom: isExpanded ? Radius.zero : const Radius.circular(20),
                              ),
                              onTap: () => setState(() => expandedColumns[colId] = !isExpanded),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                    bottom: Radius.circular(20), // luôn bo tròn khi thu gọn
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedRotation(
                                      turns: isExpanded ? 0 : -0.25,
                                      duration: const Duration(milliseconds: 300),
                                      child: const Icon(Icons.expand_more_rounded,
                                          color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        colName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17),
                                      ),
                                    ),
                                    if (isLastColumn)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(Icons.task_alt_rounded, color: Colors.white),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "${tasks.length}",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.add_task_rounded,
                                          color: Colors.white),
                                      onPressed: () => _createTask(colId),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Nội dung task – chỉ hiện khi mở rộng
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                              child: AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: tasks.isEmpty
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(40),
                                        color: Colors.grey[50],
                                        child: const Column(
                                          children: [
                                            Icon(Icons.inbox_rounded,
                                                size: 48, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text("Chưa có công việc",
                                                style: TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(12),
                                        itemCount: tasks.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                                        itemBuilder: (_, i) {
                                          final task = tasks[i];
                                          final assignees = (task['nguoi_duoc_phan_cong']
                                                  as List?)
                                              ?.cast<Map<String, dynamic>>() ??
                                              [];

                                          return Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16)),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () => _showTaskDetail(task, colId),
                                              child: Padding(
                                                padding: const EdgeInsets.all(14),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 66,
                                                      decoration: BoxDecoration(
                                                        color: _getPriorityColor(task['DO_UUTIEN']),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(task['TEN_CONGVIEC'] ?? "",
                                                              style: const TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 15)),
                                                          if (task['MOTA']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true) ...[
                                                            const SizedBox(height: 4),
                                                            Text(task['MOTA'],
                                                                style: TextStyle(
                                                                    color: Colors.grey[700],
                                                                    fontSize: 13),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis),
                                                          ],
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              if (task['DO_UUTIEN'] != null)
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                          horizontal: 8,
                                                                          vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: _getPriorityColor(
                                                                            task['DO_UUTIEN'])
                                                                        .withOpacity(0.15),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8),
                                                                  ),
                                                                  child: Text(task['DO_UUTIEN'],
                                                                      style: TextStyle(
                                                                          color:
                                                                              _getPriorityColor(task['DO_UUTIEN']),
                                                                          fontSize: 11,
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                ),
                                                              const SizedBox(width: 8),
                                                              if (task['NGAY_HETHAN'] != null)
                                                                Text(
                                                                    "Hạn: ${DateFormat('dd/MM').format(DateTime.parse(task['NGAY_HETHAN']))}",
                                                                    style: const TextStyle(
                                                                        fontSize: 12,
                                                                        color: Colors.grey)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        _buildAssigneesAvatars(assignees),
                                                        const SizedBox(height: 8),
                                                        isLastColumn
                                                            ? const Icon(Icons.check_circle_rounded,
                                                                color: Colors.green, size: 28)
                                                            : IconButton(
                                                                icon: const Icon(
                                                                    FluentIcons
                                                                        .arrow_right_20_filled,
                                                                    color: Colors.green),
                                                                onPressed: () =>
                                                                    _moveToNextColumn(
                                                                        task['ID_CONGVIEC']
                                                                            as int,
                                                                        colId),
                                                              ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                crossFadeState:
                                    isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 350),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ==================== LIST VIEW ====================
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(FluentIcons.filter_24_filled,
                                  color: Colors.deepPurple),
                              const SizedBox(width: 12),
                              const Text("Lọc theo thành viên",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              TextButton.icon(
                                  onPressed: () =>
                                      setState(() => filteredUserIds.clear()),
                                  icon: const Icon(Icons.clear_all, size: 18),
                                  label: const Text("Xóa bộ lọc"),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.deepPurple)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.deepPurple.shade200),
                                borderRadius: BorderRadius.circular(16)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                hint: Text(
                                    filteredUserIds.isEmpty
                                        ? "Tất cả thành viên"
                                        : "Đã chọn ${filteredUserIds.length} người",
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w500)),
                                items: members.map((m) {
                                  final id = m['ID_NGUOIDUNG'] as int;
                                  final name = m['HODEM_VA_TEN'] as String;
                                  return DropdownMenuItem(
                                    value: id,
                                    child: StatefulBuilder(
                                      builder: (context, setState) => CheckboxListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(name,
                                            style: const TextStyle(fontSize: 14)),
                                        value: filteredUserIds.contains(id),
                                        activeColor: Colors.deepPurple,
                                        onChanged: (v) {
                                          this.setState(() {
                                            v == true
                                                ? filteredUserIds.add(id)
                                                : filteredUserIds.remove(id);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (_) {},
                              ),
                            ),
                          ),
                          if (filteredUserIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 8,
                                children: filteredUserIds.map((id) {
                                  final name = members
                                      .firstWhere((m) => m['ID_NGUOIDUNG'] == id)[
                                      'HODEM_VA_TEN'];
                                  return Chip(
                                    backgroundColor: Colors.deepPurple.shade100,
                                    label: Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    onDeleted: () =>
                                        setState(() => filteredUserIds.remove(id)),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasksByColumn.values
                            .expand((e) => e)
                            .where((task) {
                          final assigneeIds = (task['nguoi_duoc_phan_cong']
                                  as List?)
                              ?.map((e) => e['ID_NGUOIDUNG'] as int)
                              .toSet() ??
                              {};
                          return filteredUserIds.isEmpty ||
                              assigneeIds.any(filteredUserIds.contains);
                        }).length,
                        itemBuilder: (_, i) {
                          final filteredTasks = tasksByColumn.values
                              .expand((e) => e)
                              .where((task) {
                            final assigneeIds = (task['nguoi_duoc_phan_cong']
                                    as List?)
                                ?.map((e) => e['ID_NGUOIDUNG'] as int)
                                .toSet() ??
                                {};
                            return filteredUserIds.isEmpty ||
                                assigneeIds.any(filteredUserIds.contains);
                          }).toList();

                          final task = filteredTasks[i];
                          final assignees = (task['nguoi_duoc_phan_cong']
                                  as List?)
                              ?.cast<Map<String, dynamic>>() ??
                              [];
                          final colName = columns.firstWhere(
                              (c) => c['ID_COT'] == task['ID_COT'],
                              orElse: () => {'TEN_COT': 'Không xác định'})[
                              'TEN_COT'] as String;

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                  backgroundColor:
                                      _getPriorityColor(task['DO_UUTIEN']),
                                  child: Text(
                                      task['TEN_CONGVIEC']
                                                  .toString()
                                                  .isNotEmpty ==
                                              true
                                          ? task['TEN_CONGVIEC'][0].toUpperCase()
                                          : "?",
                                      style:
                                          const TextStyle(color: Colors.white))),
                              title: Text(task['TEN_CONGVIEC'] ?? "",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Row(
                                children: [
                                  Chip(
                                      label: Text(colName,
                                          style: const TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.deepPurple.shade50),
                                  const SizedBox(width: 8),
                                  if (assignees.isNotEmpty)
                                    _buildAssigneesAvatars(assignees.take(3).toList()),
                                ],
                              ),
                              trailing: task['NGAY_HETHAN'] != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 16, color: Colors.grey),
                                        Text(
                                            DateFormat('dd/MM').format(
                                                DateTime.parse(task['NGAY_HETHAN'])),
                                            style: const TextStyle(fontSize: 12)),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}