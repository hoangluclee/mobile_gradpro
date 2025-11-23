import 'package:flutter/material.dart';
import 'package:doancunhan/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  Map<String, dynamic>? myGroup;
  Map<String, dynamic>? currentUser;
  List<dynamic> availableGroups = [];
  List<dynamic> invitations = [];
  List<Map<String, dynamic>> plans = [];

  bool isLoading = true;
  int? selectedPlanId;
  final TextEditingController _groupNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  int? _toInt(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()) ?? 0);
  Map<String, dynamic> _safeMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : {};
  List<dynamic> _safeList(dynamic v) => v is List ? v : [];

  // ================= LOAD ALL – HOÀN HẢO 100% =================
 // ================= LOAD ALL – ĐÃ HOÀN CHỈNH 100% =================
Future<void> _loadAll() async {
  setState(() => isLoading = true);
  try {
    currentUser = await ApiService.getCurrentUser();
    final rawGroup = await ApiService.getMyGroup();
    myGroup = rawGroup ?? {"has_group": false};

    final hasGroup = myGroup?['has_group'] == true;

    if (hasGroup) {
      // CÓ NHÓM → LẤY KẾ HOẠCH TỪ GROUP HOẶC API
      final groupData = _safeMap(myGroup?['group_data']);
      final planFromGroup = groupData['kehoach'] ?? groupData['thesis_plan'];

      if (planFromGroup is Map && planFromGroup['TEN_KEHOACH'] != null) {
        myGroup!['plan_detail'] = planFromGroup;
      } else {
        final plan = await ApiService.getMyPlan();
        if (plan.isNotEmpty) {
          myGroup!['plan_detail'] = plan;
        }
      }

      // ================= THÊM 3 DÒNG SIÊU QUAN TRỌNG ĐỂ LƯU GROUP ID =================
      final groupId = _toInt(groupData['ID_NHOM']);
      if (groupId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_group_id', groupId);
        debugPrint("Đã lưu current_group_id = $groupId"); // Để kiểm tra log
      }
      // ===========================================================================

    } else {
      // CHƯA CÓ NHÓM → LẤY DANH SÁCH KẾ HOẠCH ĐANG ACTIVE ĐỂ TẠO NHÓM
      final rawPlans = await ApiService.getActivePlans();
      plans = _safeList(rawPlans).cast<Map<String, dynamic>>();

      if (plans.isNotEmpty && selectedPlanId == null) {
        selectedPlanId = _toInt(plans.first['ID_KEHOACH']);
        if (selectedPlanId != null) {
          availableGroups = _safeList(await ApiService.getAvailableGroups(selectedPlanId!));
        }
      }
      invitations = _safeList(await ApiService.getPendingInvitations());
    }
  } catch (e) {
    debugPrint("Load error: $e");
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
   // ================= CHECK LEADER – 
  bool get isLeader {
    if (myGroup == null || myGroup?['has_group'] != true) return false;

    final group = _safeMap(myGroup?['group_data']);
    final leaderId = _toInt(group['ID_NHOMTRUONG']);
    if (leaderId == null) return false;

    // LẤY TẤT CẢ ID THÀNH VIÊN TRONG NHÓM
    final memberIds = _safeList(group['thanhviens']).map((m) {
      final u = _safeMap(_safeMap(m)['nguoidung'] ?? m);
      return _toInt(u['ID_NGUOIDUNG']);
    }).toList();

    // KIỂM TRA XEM ID NHÓM TRƯỞNG CÓ TRONG DANH SÁCH THÀNH VIÊN KHÔNG
    return memberIds.contains(leaderId);
  }
  // ================= CÁC HÀM THIẾU ĐÃ ĐƯỢC THÊM LẠI =================
  Future<void> _createGroup() async {
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty || selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên nhóm và chọn kế hoạch")));
      return;
    }
    setState(() => isLoading = true);
    final ok = await ApiService.createGroup(name, selectedPlanId!);
    if (ok) _groupNameCtrl.clear();
    await _loadAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? "Tạo nhóm thành công!" : "Tạo nhóm thất bại")));
  }

  Future<void> _joinGroup(int groupId) async {
    final ok = await ApiService.joinGroup(groupId);
    await _loadAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? "Đã gửi yêu cầu tham gia" : "Gửi thất bại")));
  }

  Future<void> _handleInvitation(int? id, bool accept) async {
    if (id == null) return;
    final ok = await ApiService.handleInvitation(id, accept);
    if (ok) await _loadAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? "Chấp nhận lời mời" : "Từ chối lời mời")));
  }

  Future<void> _handleJoinRequest(int? groupId, int? requestId, bool accept) async {
    if (groupId == null || requestId == null) return;
    final ok = await ApiService.handleJoinRequest(groupId, requestId, accept);
    if (ok) await _loadAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? "Đã chấp nhận thành viên" : "Đã từ chối")));
  }

  // ================= INVITE DIALOG =================
  void _showInviteDialog() async {
    final searchCtrl = TextEditingController();
    List<dynamic> results = [];
    bool isSearching = true;

    final planId = _toInt(myGroup?['group_data']?['ID_KEHOACH']);
    if (planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không lấy được kế hoạch nhóm")));
      return;
    }

    try {
      results = await ApiService.searchAvailableStudents(planId: planId, search: "");
    } catch (_) {}
    isSearching = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1, color: Colors.deepPurple, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text("Mời thành viên vào nhóm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 520,
            child: Column(
              children: [
                TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Tìm tên hoặc mã sinh viên",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : results.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_alt_rounded, size: 70, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                const Text("Không có sinh viên nào chưa có nhóm", style: TextStyle(fontSize: 1, color: Colors.grey)),
                              ],
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final item = _safeMap(results[i]);
                                final user = _safeMap(item['nguoidung'] ?? item);

                                final maSV = item['MA_DINHDANH'] ?? user['MA_DINHDANH'] ?? '';
                                final name = user['HODEM_VA_TEN'] ?? "Không tên";
                                final lop = user['sinhvien']?['TEN_LOP'] ?? "";

                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.deepPurple,
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Expanded(child: Text("MSSV: $maSV", style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        if (lop.isNotEmpty) const SizedBox(width: 8),
                                        if (lop.isNotEmpty) Expanded(child: Text("Lớp: $lop", style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    trailing: ElevatedButton.icon(
                                      onPressed: () async {
                                        final groupId = _toInt(myGroup?['group_data']?['ID_NHOM']);
                                        if (groupId == null) return;

                                        final ok = await ApiService.inviteMember(groupId: groupId, maDinhDanh: maSV);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(ok ? "Đã gửi lời mời cho $name" : "Gửi thất bại"),
                                            backgroundColor: ok ? Colors.green : Colors.red,
                                          ),
                                        );
                                        if (ok) Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.send, size: 16),
                                      label: const Text("Mời", style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

 // ================= MEMBER CARD – ĐÃ THÊM MÃ SINH VIÊN =================
Widget _memberCard(Map<String, dynamic> user, {bool isLeader = false}) {
  final name = user['HODEM_VA_TEN'] ?? "Không tên";
  final maSV = user['MA_DINHDANH'] ?? "Chưa có mã"; // ← THÊM MÃ SINH VIÊN
  final email = user['EMAIL'] ?? "";
  final lop = user['sinhvien']?['TEN_LOP'] ?? "";

  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isLeader ? Colors.orange : Colors.deepPurple,
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      title: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MSSV: $maSV", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)), // ← MÃ SV ĐẬM ĐẸP
          if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (lop.isNotEmpty) Text("Lớp: $lop", style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: isLeader
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                "Nhóm trưởng",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            )
          : null,
    ),
  );
}
  Widget _buildMyGroup() {
  final group = _safeMap(myGroup?['group_data']);
  final membersRaw = _safeList(group['thanhviens']);
  final leaderId = _toInt(group['ID_NHOMTRUONG']);

  String planName = "Chưa xác định";
  if (myGroup?['plan_detail'] is Map) {
    planName = myGroup!['plan_detail']['TEN_KEHOACH'] ?? myGroup!['plan_detail']['TEN_DOT'] ?? "Chưa xác định";
  }

  // THÊM ĐOẠN NÀY – LẤY TÊN ĐỀ TÀI CHÍNH XÁC 100%
String topicName = "Chưa đăng ký đề tài";
final phancong = group['phancong_detai_nhom'] as Map<String, dynamic>?;
final detai = phancong?['detai'] as Map<String, dynamic>?;

if (detai != null && detai['TEN_DETAI'] != null && detai['TEN_DETAI'].toString().trim().isNotEmpty) {
  topicName = detai['TEN_DETAI'].toString();
}

  Map<String, dynamic>? leaderUser;
  for (var m in membersRaw) {
    final u = _safeMap(_safeMap(m)['nguoidung'] ?? m);
    if (_toInt(u['ID_NGUOIDUNG']) == leaderId) {
      leaderUser = u;
      break;
    }
  }

  final members = membersRaw
      .map((m) => _safeMap(_safeMap(m)['nguoidung'] ?? m))
      .where((u) => _toInt(u['ID_NGUOIDUNG']) != leaderId)
      .toList();

  final pendingRequests = _safeList(group['yeucaus'] ?? group['pending_requests'] ?? []);

  final bool isLeaderNow = isLeader;

  return RefreshIndicator(
    onRefresh: _loadAll,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GROUP CARD – ĐÃ THÊM TÊN ĐỀ TÀI
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups, size: 32, color: Colors.deepPurple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          group['TEN_NHOM'] ?? "Nhóm của bạn",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Expanded(child: Text("Kế hoạch: $planName", style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.deepPurple), // Icon đề tài
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Đề tài: $topicName",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: topicName == "Chưa đăng ký đề tài" ? FontWeight.normal : FontWeight.bold,
                            color: topicName == "Chưa đăng ký đề tài" ? Colors.grey[700] : Colors.deepPurple[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Expanded(child: Text("Trạng thái: ${group['TRANGTHAI'] ?? 'Đang thực hiện'}", style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await ApiService.leaveGroup();
                          await _loadAll();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? "Rời nhóm thành công" : "Rời nhóm thất bại")),
                          );
                        },
                        icon: const Icon(Icons.exit_to_app, size: 16),
                        label: const Text("Rời nhóm", style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${members.length + (leaderUser != null ? 1 : 0)} / 4 thành viên",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

            const SizedBox(height: 30),

            const Text("Nhóm trưởng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            leaderUser != null ? _memberCard(leaderUser, isLeader: true) : const Text("Đang tải..."),

            const SizedBox(height: 30),

            const Text("Thành viên", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            members.isEmpty
                ? Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text("Chưa có thành viên khác", style: TextStyle(color: Colors.grey[700], fontSize: 15))),
                    ),
                  )
                : Column(
                    children: members
                        .map((u) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _memberCard(u),
                            ))
                        .toList(),
                  ),

                        // ================= CHỈ NHÓM TRƯỞNG MỚI THẤY NÚT MỜI VÀ PHẦN YÊU CẦU =================
            if (isLeaderNow) ...[
              // NÚT MỜI
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton.icon(
                    onPressed: _showInviteDialog,
                    icon: const Icon(Icons.person_add_alt_1, size: 32),
                    label: const Text("MỜI THÀNH VIÊN MỚI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      shadowColor: Colors.deepPurple.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

              // YÊU CẦU XIN VÀO NHÓM
              const SizedBox(height: 40),
              const Text("Yêu cầu xin vào nhóm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              pendingRequests.isEmpty
                  ? Card(
                      elevation: 4,
                      color: Colors.grey[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 36, color: Colors.grey[500]),
                              const SizedBox(width: 12),
                              Text("Chưa có yêu cầu nào", style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: pendingRequests.map((req) {
                        final r = _safeMap(req);
                        final user = _safeMap(r['nguoidung'] ?? r);
                        final reqId = _toInt(r['ID']);
                        final groupId = _toInt(group['ID_NHOM']);

                        return Card(
                          elevation: 6,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                (user['HODEM_VA_TEN'] as String?)?.isNotEmpty == true
                                    ? (user['HODEM_VA_TEN'] as String)[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            title: Text(user['HODEM_VA_TEN'] ?? "Không rõ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(user['EMAIL'] ?? "", style: const TextStyle(fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                  onPressed: () => _handleJoinRequest(groupId, reqId, true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                                  onPressed: () => _handleJoinRequest(groupId, reqId, false),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ] else ...[
              // THÀNH VIÊN THƯỜNG → KHÔNG THẤY GÌ HẾT, CHỈ CÓ KHOẢNG TRỐNG NHỎ ĐỂ KHÔNG LỆCH LAYOUT
              const SizedBox(height: 80),
            ],

            const SizedBox(height: 60),

            const SizedBox(height: 60),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ================= PHẦN CHƯA CÓ NHÓM – ĐÃ CÓ ĐẦY ĐỦ NHƯ FILE GỐC =================
  Widget _buildNoGroup() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: const Color.fromARGB(255, 242, 235, 255), 
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 36, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Bạn chưa có nhóm",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent[700]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _groupNameCtrl,
                      decoration: InputDecoration(
                        labelText: "Tên nhóm mới",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedPlanId,
                      hint: const Text("Chọn kế hoạch"),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Kế hoạch",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (v) async {
                        setState(() => selectedPlanId = v);
                        if (v != null) {
                          final data = await ApiService.getAvailableGroups(v);
                          setState(() => availableGroups = _safeList(data));
                        }
                      },
                      items: plans.map((p) {
                        final id = _toInt(p['ID_KEHOACH'] ?? p['ID']);
                        final name = p['TEN_DOT'] ?? 'Kế hoạch $id';
                        return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 15)));
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _createGroup,
                        icon: const Icon(Icons.group_add, size: 28),
                        label: const Text("Tạo nhóm mới", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text("Nhóm đang tuyển thành viên", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            availableGroups.isEmpty
                ? Card(
                    elevation: 4,
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text("Không có nhóm nào đang mở", style: TextStyle(color: Colors.grey[700], fontSize: 15))),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: availableGroups.length,
                    itemBuilder: (_, i) {
                      final g = _safeMap(availableGroups[i]);
                      final gid = _toInt(g['ID_NHOM']);
                      final daGui = g['da_gui_yeu_cau'] == true;
                      return Card(
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Text(g['TEN_NHOM'] ?? "Nhóm", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text("${g['SO_THANHVIEN_HIENTAI'] ?? 1}/4 thành viên", style: const TextStyle(fontSize: 14)),
                          trailing: ElevatedButton(
                            onPressed: daGui || gid == null ? null : () => _joinGroup(gid!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: daGui ? Colors.grey : Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text(daGui ? "Đã gửi" : "Xin vào", style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 30),
            const Text("Lời mời vào nhóm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            invitations.isEmpty
                ? Card(
                    elevation: 4,
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text("Không có lời mời nào", style: TextStyle(color: Colors.grey[700], fontSize: 15))),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invitations.length,
                    itemBuilder: (_, i) {
                      final inv = _safeMap(invitations[i]);
                      final nhom = _safeMap(inv['nhom']);
                      final invId = _toInt(inv['ID']);
                      return Card(
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Text(nhom['TEN_NHOM'] ?? "Nhóm mời bạn", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.check, color: Colors.green, size: 28), onPressed: () => _handleInvitation(invId, true)),
                              IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 28), onPressed: () => _handleInvitation(invId, false)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGroup = myGroup?['has_group'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý nhóm đồ án", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        elevation: 8,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A5AE0), Color(0xFF8F74F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : hasGroup
              ? _buildMyGroup()
              : _buildNoGroup(),
    );
  }
}