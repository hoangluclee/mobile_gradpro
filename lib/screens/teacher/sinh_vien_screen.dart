// UPDATED: Hiển thị đầy đủ tất cả thành viên nhóm hướng dẫn

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SinhVienScreen extends StatelessWidget {
  const SinhVienScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sinh viên hướng dẫn",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getMyGuidingGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 90, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  const Text(
                    "Chưa có nhóm nào",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final g = groups[i];

              // LẤY TÊN NHÓM
              final String tenNhom =
                  g['TEN_NHOM']?.toString() ?? g['ten_nhom']?.toString() ??
                  g['MA_NHOM']?.toString() ?? "Nhóm ${g['ID_NHOM'] ?? i + 1}";

              // LẤY ĐỀ TÀI
              final detai = g['detai'] ?? g['detai_nhom'] ?? {};
              final String tenDeTai = detai['TEN_DETAI']?.toString() ??
                  detai['ten_de_tai']?.toString() ?? "Chưa có đề tài";

              // CHỮ CÁI ĐẦU
              final String firstLetter = tenNhom.isNotEmpty
                  ? tenNhom[0].toUpperCase()
                  : "N";

              // LẤY DANH SÁCH THÀNH VIÊN (HỢP NHẤT)
              final List<dynamic> members = [];
              if (g['thanhviens'] is List) members.addAll(g['thanhviens']);
              if (g['thanhvienNhom'] is List) members.addAll(g['thanhvienNhom']);
              if (g['sinhvien'] is List) members.addAll(g['sinhvien']);
              if (g['members'] is List) members.addAll(g['members']);

              // XOÁ TRÙNG
              final uniqueMembers = members.toSet().toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.teal,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    tenNhom,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenDeTai,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 18, color: Colors.teal),
                          const SizedBox(width: 6),
                          Text(
                            "${uniqueMembers.length} thành viên",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  children: [
                    const Divider(height: 1, thickness: 1),

                    // DANH SÁCH THÀNH VIÊN
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: uniqueMembers.isEmpty
                            ? [
                                const Center(
                                  child: Text(
                                    "Chưa có thành viên",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              ]
                            : uniqueMembers.map<Widget>((m) {
                                final user = m['nguoidung'] ??
                                    m['sinhvien'] ??
                                    m;

                                final String hoTen = user['HODEM_VA_TEN']?.toString() ??
                                    user['name']?.toString() ??
                                    "Sinh viên";

                                final String email = user['EMAIL']?.toString() ??
                                    user['email']?.toString() ??
                                    "";

                                final String lop = user['TEN_LOP']?.toString() ??
                                    user['sinhvien']?['TEN_LOP']?.toString() ??
                                    "Chưa có lớp";

                                final bool isNhomTruong =
                                    m['LA_NHOMTRUONG'] == 1 ||
                                    user['ID_NGUOIDUNG'] ==
                                        g['ID_NHOMTRUONG'];

                                return Card(
                                  color: Colors.teal.withOpacity(0.05),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: isNhomTruong
                                          ? Colors.orange
                                          : Colors.teal,
                                      child: Text(
                                        hoTen.isNotEmpty
                                            ? hoTen[0]
                                            : "S",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      hoTen,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (email.isNotEmpty)
                                          Text(email,
                                              style: const TextStyle(
                                                  fontSize: 13.5)),
                                        Text(
                                          "Lớp: $lop",
                                          style: const TextStyle(
                                              fontSize: 13.5),
                                        ),
                                      ],
                                    ),
                                    trailing: isNhomTruong
                                        ? Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              "Nhóm trưởng",
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}