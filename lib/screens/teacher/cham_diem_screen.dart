import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChamDiemScreen extends StatelessWidget {
  const ChamDiemScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        title: const Text("Chấm điểm đồ án"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 3,
      ),

      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getMyGradingTasks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => {},
            color: Colors.green,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, i) => _buildTaskCard(context, tasks[i]),
            ),
          );
        },
      ),
    );
  }

  // ======================= EMPTY STATE ==========================
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      children: [
        Column(
          children: [
            Icon(Icons.task_alt, size: 110, color: Colors.green.shade300),
            const SizedBox(height: 28),
            const Text(
              "Không có nhiệm vụ chấm điểm",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Bạn chưa được phân công chấm nhóm nào.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  // ======================= CARD NHIỆM VỤ ==========================
  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> t) {
    final tenNhom = t['ten_nhom']?.toString().trim();
    final String displayTenNhom =
        (tenNhom == null || tenNhom.isEmpty) ? "Nhóm ${t['ID_NHOM']}" : tenNhom;

    final tenDeTai = t['ten_de_tai']?.toString().trim();
    final String displayTenDT =
        (tenDeTai == null || tenDeTai.isEmpty) ? "Chưa có đề tài" : tenDeTai;

    // Icon theo loại chấm
    IconData icon = Icons.how_to_vote;
    if (t['loai'] == 'huongdan') icon = Icons.school;
    if (t['loai'] == 'phanbien') icon = Icons.rate_review;

    final loaiViet = t['loai_viet'] ?? t['loai'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green[800], size: 26),
        ),

        title: Text(
          displayTenNhom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              displayTenDT,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Loại: $loaiViet",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),

        trailing: t['da_cham'] == true
            ? const Icon(Icons.check_circle, color: Colors.green, size: 26)
            : const Icon(Icons.pending, color: Colors.orange, size: 26),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChamDiemDetailScreen(task: t),
            ),
          );
        },
      ),
    );
  }
}

class ChamDiemDetailScreen extends StatelessWidget {
  final dynamic task;
  const ChamDiemDetailScreen({required this.task, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chấm điểm"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          "Form chấm điểm\n(Sẽ làm sau)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.grey[700]),
        ),
      ),
    );
  }
}
