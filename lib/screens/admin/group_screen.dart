import 'package:flutter/material.dart';
import 'package:doancunhan/services/api_service.dart';
import 'package:doancunhan/screens/admin/group_members_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  String? selectedKeHoachId;
  List<dynamic> keHoachList = [];
  List<dynamic> nhomList = [];
  bool isLoadingPlans = false;
  bool isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    _fetchKeHoachList();
  }

  // Lấy danh sách kế hoạch
  Future<void> _fetchKeHoachList() async {
    setState(() => isLoadingPlans = true);

    final data = await ApiService.getKeHoachList();
    print(" KẾ HOẠCH: $data");

    setState(() {
      keHoachList = data;
      isLoadingPlans = false;
    });
  }

  // Lấy nhóm theo kế hoạch
  Future<void> _fetchNhomList(String keHoachId) async {
    setState(() => isLoadingGroups = true);

    final dynamic res = await ApiService.getNhomByKeHoach(keHoachId);
    print("✅ NHÓM RESPONSE: $res");

    setState(() {
      if (res == null) {
        nhomList = [];
      } else if (res is List) {
        // API returned a list directly
        nhomList = res;
      } else if (res is Map && res["data"] is List) {
        // API returned an object with a "data" list
        nhomList = res["data"];
      } else {
        nhomList = [];
      }
      isLoadingGroups = false;
    });
  }

  // Dropdown chọn kế hoạch
  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📋 Chọn kế hoạch",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedKeHoachId,
              isExpanded: true,
              hint: const Text("Chọn kế hoạch"),
              items: keHoachList.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem<String>(
                  value: item["ID_KEHOACH"].toString(),
                  child: Text(item["TEN_DOT"] ?? "Không tên"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedKeHoachId = value;
                  nhomList = [];
                });
                if (value != null) {
                  _fetchNhomList(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Danh sách nhóm
  Widget _buildNhomList() {
    if (selectedKeHoachId == null) {
      return const Center(child: Text("Vui lòng chọn 1 kế hoạch."));
    }

    if (isLoadingGroups) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.indigo));
    }

    if (nhomList.isEmpty) {
      return const Center(child: Text("Không có nhóm nào."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nhomList.length,
      itemBuilder: (context, index) {
        final nhom = nhomList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(nhom["TEN_NHOM"] ?? "Nhóm"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(
                    nhomId: nhom["ID_NHOM"].toString(),
                    tenNhom: nhom["TEN_NHOM"] ?? "Nhóm",
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý nhóm đồ án"),
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.grey.shade100,
      body: isLoadingPlans
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : RefreshIndicator(
              onRefresh: () async {
                if (selectedKeHoachId != null) {
                  await _fetchNhomList(selectedKeHoachId!);
                }
                await _fetchKeHoachList();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDropdown(),
                    _buildNhomList(),
                  ],
                ),
              ),
            ),
    );
  }
}
