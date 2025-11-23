// lib/screens/teacher/hoidong_screen_teacher.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class HoiDongGiangVienScreen extends StatefulWidget {
  const HoiDongGiangVienScreen({super.key});

  @override
  State<HoiDongGiangVienScreen> createState() => _HoiDongGiangVienScreenState();
}

class _HoiDongGiangVienScreenState extends State<HoiDongGiangVienScreen> {
  List<dynamic> hoiDongs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHoiDong();
  }

  Future<void> _loadHoiDong() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.dio.get('/giangvien/my-hoidong');
      final data = res.data;

      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'];
      }

      setState(() {
        hoiDongs = list;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải hội đồng: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        title: const Text(
          "Hội đồng của tôi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.deepPurple.withOpacity(0.5),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHoiDong,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : hoiDongs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHoiDong,
                  color: Colors.deepPurple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: hoiDongs.length,
                    itemBuilder: (context, index) =>
                        _buildHoiDongCard(hoiDongs[index]),
                  ),
                ),
    );
  }

  // ======================= EMPTY STATE ============================
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadHoiDong,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Icon(Icons.groups_outlined,
                    size: 100, color: Colors.deepPurple.shade200),
              ),
              const SizedBox(height: 30),
              const Text(
                "Chưa được phân công hội đồng",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                "Khi được phân công, hội đồng sẽ xuất hiện ở đây.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================= CARD ===============================
  Widget _buildHoiDongCard(Map<String, dynamic> hd) {
    final tenHoiDong = hd['TEN_HOIDONG'] ?? "Hội đồng không tên";
    final ngayBaoCao = hd['NGAY_BAOCAO'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(hd['NGAY_BAOCAO']))
        : "Chưa xác định";
    final gio = hd['GIO_BAOCAO']?.substring(0, 5) ?? "--:--";
    final phong = hd['PHONG'] ?? "Chưa có";
    final soThanhVien = (hd['giangviens'] as List?)?.length ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.08),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.deepPurple.shade50.withOpacity(0.4),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple,
            child: Text(
              tenHoiDong.substring(0, 1),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),

          title: Text(
            tenHoiDong,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "$ngayBaoCao • $gio • Phòng $phong",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        "$soThanhVien thành viên",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),

          children: [
            const SizedBox(height: 6),
            _buildGiangVienSection(hd),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  // ======================= SECTION GIẢNG VIÊN ===============================
  Widget _buildGiangVienSection(Map<String, dynamic> hd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Thành viên hội đồng",
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 12),

        ...(hd['giangviens'] as List? ?? []).map((gv) {
          final ten = gv['TEN_GIANGVIEN'] ?? "Không rõ";
          final raw = (gv['VAITRO'] ?? "").toString().toLowerCase();

          String vaiTro = "Thành viên";
          Color color = Colors.grey;

          if (raw.contains("chutich")) {
            vaiTro = "Chủ tịch";
            color = Colors.redAccent;
          } else if (raw.contains("thuky")) {
            vaiTro = "Thư ký";
            color = Colors.blueAccent;
          } else if (raw.contains("phanbien")) {
            vaiTro = "Phản biện";
            color = Colors.orange;
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.15),
                  child: Text(
                    ten[0],
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    ten,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Chip(
                  label: Text(
                    vaiTro,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  backgroundColor: color.withOpacity(0.15),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}