import 'package:flutter/material.dart';
import 'package:doancunhan/services/api_service.dart';
import 'package:doancunhan/screens/admin/edit_hoidong_screen.dart';

class HoiDongScreen extends StatefulWidget {
  const HoiDongScreen({super.key});

  @override
  State<HoiDongScreen> createState() => _HoiDongScreenState();
}

class _HoiDongScreenState extends State<HoiDongScreen> {
  List<dynamic> dsHoiDong = [];
  Map<String, dynamic>? selectedDetail;
  bool loading = true;
  int? selectedId;

  @override
  void initState() {
    super.initState();
    _loadHoiDong();
  }

  Future<void> _loadHoiDong() async {
    try {
      final data = await ApiService.getHoiDongList();
      setState(() {
        dsHoiDong = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  Future<void> _showDetail(int id) async {
    setState(() {
      selectedId = id;
      selectedDetail = null;
      loading = true;
    });

    try {
      final data = await ApiService.getHoiDongDetail(id);
      setState(() {
        selectedDetail = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải chi tiết: $e')));
    }
  }

  void _goToEdit(Map<String, dynamic> hoidong) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditHoiDongScreen(hoidong: hoidong)),
    );
    _loadHoiDong();
    if (selectedId != null) _showDetail(selectedId!);
  }

  // 🔹 Giao diện chi tiết toàn màn hình
  Widget _buildDetailFull() {
    final hd = selectedDetail!;
    final gvList = hd['giangviens'] as List<dynamic>? ?? [];
    final nhomList = hd['nhoms'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Chi tiết Hội đồng"),
        backgroundColor: const Color(0xFF3E4C88),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => selectedId = null),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin hội đồng
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hd['TEN_HOIDONG'] ?? 'Không có tên',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E4C88),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row("ID Hội đồng", "${hd['ID_HOIDONG']}"),
                  _row("Loại", hd['LOAI'] ?? '-'),
                  _row("Ngày báo cáo", hd['NGAY_BAOCAO'] ?? '-'),
                  _row("Giờ báo cáo", hd['GIO_BAOCAO'] ?? '-'),
                  _row("Phòng", hd['PHONG'] ?? '-'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Giảng viên
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Danh sách Giảng viên",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E4C88),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (gvList.isEmpty)
                    const Text("Chưa có giảng viên nào."),
                  ...gvList.map<Widget>((gv) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          "${gv['HO_TEN'] ?? gv['nguoidung']?['HODEM_VA_TEN'] ?? 'Không rõ'} - Vai trò: ${gv['pivot']?['VAITRO'] ?? '-'}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      )).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nhóm phụ trách
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nhóm phụ trách",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E4C88),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (nhomList.isEmpty)
                    const Text("Chưa có nhóm nào."),
                  ...nhomList.map<Widget>((n) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          "${n['TEN_NHOM'] ?? 'Không rõ'} (ID: ${n['ID_NHOM']})",
                          style: const TextStyle(fontSize: 15),
                        ),
                      )).toList(),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Center(
              child: ElevatedButton(
                onPressed: () => _goToEdit(hd),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E4C88),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Sửa hội đồng này",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.w500))),
          Expanded(
              flex: 4,
              child:
                  Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedId != null && selectedDetail != null) {
      return _buildDetailFull();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Danh sách Hội đồng"),
        backgroundColor: const Color(0xFF3E4C88),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dsHoiDong.length,
              itemBuilder: (context, index) {
                final hd = dsHoiDong[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(hd['TEN_HOIDONG'] ?? 'Không có tên',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text("Loại: ${hd['LOAI'] ?? '-'}"),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.grey, size: 18),
                    onTap: () => _showDetail(hd['ID_HOIDONG']),
                  ),
                );
              },
            ),
    );
  }
}
