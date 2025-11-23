import 'package:flutter/material.dart';
import 'package:doancunhan/services/api_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final String nhomId;
  final String tenNhom;

  const GroupDetailScreen({
    Key? key,
    required this.nhomId,
    required this.tenNhom,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? nhomData;
  Map<String, dynamic>? hoiDongData;
  List<dynamic> giangVienHoiDong = [];
  List<dynamic> nhomHoiDong = [];
  List<dynamic> sinhViens = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final nhom = await ApiService.getChiTietNhom(widget.nhomId);
      nhomData = (nhom != null && nhom.isNotEmpty) ? nhom : null;
      sinhViens = nhomData!['sinhviens'] ?? [];

      final hoiDongId = nhomData!['ID_HOIDONG']?.toString();
      if (hoiDongId != null && hoiDongId.isNotEmpty) {
        final hdRes = await ApiService.getHoiDongDetail(int.parse(hoiDongId));
        final hdObject = hdRes["data"] ?? hdRes;
        if (hdObject != null && hdObject.isNotEmpty) {
          hoiDongData = hdObject;
          giangVienHoiDong = hdObject["giangviens"];
          nhomHoiDong = hdObject["nhoms"];
        }
      }
    } catch (e) {
      errorMessage = "Lỗi khi tải dữ liệu: $e";
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildInfoTile(String title, dynamic value) {
    final textValue =
        (value == null || value.toString().isEmpty) ? "---" : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: "$title: ",
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                  children: [
                    TextSpan(
                      text: textValue,
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children,
      {Color color = Colors.indigo}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSinhVienList() {
    if (sinhViens.isEmpty) {
      return const Text("Không có sinh viên trong nhóm.",
          style: TextStyle(color: Colors.black54));
    }

    return Column(
      children: sinhViens.map((sv) {
        final hoTen = sv['HO_TEN'] ?? sv['TEN_SV'] ?? 'Không rõ';
        final mssv = sv['MSSV'] ?? '';
        final isLeader = sv['IS_LEADER'] == true ||
            sv['TRUONGNHOM'] == 1 ||
            sv['VAITRO'] == 'Nhóm trưởng';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.indigo, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$hoTen (${mssv.isNotEmpty ? mssv : '---'})${isLeader ? ' - Nhóm trưởng' : ''}",
                  style: TextStyle(
                    fontSize: 15,
                    color: isLeader ? Colors.indigo.shade700 : Colors.black87,
                    fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 3,
        backgroundColor: Colors.indigo,
        title: const Text(
          'Chi tiết nhóm',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: Colors.indigo,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade400,
                                Colors.indigo.shade700
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.groups_rounded,
                                  color: Colors.white, size: 48),
                              const SizedBox(height: 10),
                              Text(
                                widget.tenNhom,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nhomData!['TEN_DETAI'] ?? "Chưa có đề tài",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSection("Thông tin nhóm", [
                          _buildInfoTile("Mã nhóm", nhomData!['ID_NHOM']),
                          _buildInfoTile("Tên đề tài", nhomData!['TEN_DETAI']),
                          _buildInfoTile("Mô tả đề tài", nhomData!['MOTA']),
                          _buildInfoTile("Giảng viên hướng dẫn", nhomData!['TEN_GVHD']),
                        ]),
                        _buildSection("Thành viên nhóm", [_buildSinhVienList()]),
                        if (hoiDongData != null)
                          _buildSection("Hội đồng chấm", [
                            _buildInfoTile("Tên hội đồng", hoiDongData!['TEN_HOIDONG']),
                            _buildInfoTile("Loại hội đồng", hoiDongData!['LOAI']),
                            _buildInfoTile("Ngày báo cáo", hoiDongData!['NGAY_BAOCAO']),
                            _buildInfoTile("Giờ báo cáo", hoiDongData!['GIO_BAOCAO']),
                            _buildInfoTile("Phòng báo cáo", hoiDongData!['PHONG']),
                            const SizedBox(height: 10),
                            const Divider(),
                            const Text(
                              "Giảng viên hội đồng",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo),
                            ),
                            const SizedBox(height: 8),
                            if (giangVienHoiDong.isNotEmpty)
                              ...giangVienHoiDong.map((gv) {
                                final tenGV = gv['HO_TEN'] ?? gv['nguoidung']['HODEM_VA_TEN'] ?? "Không rõ";
                                final vaiTro = gv['pivot']['VAITRO'] ?? 'Thành viên';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    "$tenGV - $vaiTro",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                );
                              })
                            else
                              const Text("Không có giảng viên trong hội đồng."),
                            const SizedBox(height: 16),
                            const Text(
                              "Nhóm phụ trách",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo),
                            ),
                            const SizedBox(height: 8),
                            if (nhomHoiDong.isNotEmpty)
                              ...nhomHoiDong.map((n) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      "${n['TEN_NHOM'] ?? 'Không rõ'} (ID: ${n['ID_NHOM']})",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ))
                            else
                              const Text("Không có nhóm nào."),
                          ])
                        else
                          _buildSection("Hội đồng chấm", [
                            const Text(
                              "Nhóm chưa được phân công hội đồng.",
                              style: TextStyle(color: Colors.black54),
                            )
                          ]),
                      ],
                    ),
                  ),
                ),
    );
  }
}
