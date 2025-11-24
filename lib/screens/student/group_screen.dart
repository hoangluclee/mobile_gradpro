// lib/screens/group/group_screen.dart
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
  List<dynamic> invitations = [];           // Lời mời nhận được (chưa có nhóm)
  List<dynamic> sentInvitations = [];       // Lời mời đã gửi đi (khi đã có nhóm)
  List<dynamic> joinRequests = [];          // Yêu cầu xin vào nhóm

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

  // Helper
  int? _toInt(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()) ?? 0);
  Map<String, dynamic> _safeMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : {};
  List<dynamic> _safeList(dynamic v) => v is List ? v : [];

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      currentUser = await ApiService.getCurrentUser();
      final rawGroup = await ApiService.getMyGroup();
      myGroup = rawGroup ?? {"has_group": false};

      final hasGroup = myGroup?['has_group'] == true;

      if (hasGroup) {
        final groupData = _safeMap(myGroup?['group_data']);
        final groupId = _toInt(groupData['ID_NHOM']);

        // Lấy tên kế hoạch
        final planFromGroup = groupData['kehoach'] ?? groupData['thesis_plan'];
        if (planFromGroup is Map) {
          myGroup!['plan_detail'] = planFromGroup;
        } else {
          final plan = await ApiService.getMyPlan();
          if (plan.isNotEmpty) myGroup!['plan_detail'] = plan;
        }

        if (groupId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('current_group_id', groupId);
        }

        // LẤY DỮ LIỆU KHI ĐÃ CÓ NHÓM
        joinRequests = _safeList(groupData['yeucaus'] ?? groupData['join_requests'] ?? []);
        sentInvitations = _safeList(groupData['loimois'] ?? []);

      } else {
        // CHƯA CÓ NHÓM
        final rawPlans = await ApiService.getActivePlans();
        plans = _safeList(rawPlans).cast<Map<String, dynamic>>();

        if (plans.isNotEmpty && selectedPlanId == null) {
          selectedPlanId = _toInt(plans.first['ID_KEHOACH']);
          if (selectedPlanId != null) {
            availableGroups = await ApiService.getAvailableGroups(selectedPlanId!);
          }
        }
        invitations = await ApiService.getPendingInvitations();
        sentInvitations = [];
        joinRequests = [];
      }
    } catch (e) {
      debugPrint("Load error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool get isLeader {
    if (myGroup == null || myGroup?['has_group'] != true) return false;
    final group = _safeMap(myGroup?['group_data']);
    final leaderId = _toInt(group['ID_NHOMTRUONG']);
    if (leaderId == null) return false;
    final currentUserId = _toInt(currentUser?['ID_NGUOIDUNG']) ?? _toInt(currentUser?['ID_SINHVIEN']);
    return leaderId == currentUserId;
  }

  // Các hành động
  Future<void> _createGroup() async {
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty || selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nhập tên nhóm và chọn đợt")));
      return;
    }
    setState(() => isLoading = true);
    final result = await ApiService.createGroup(name, selectedPlanId!);
    await _loadAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true ? "Tạo nhóm thành công!" : result['message'] ?? "Lỗi"),
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
    ));
    if (result['success'] == true) _groupNameCtrl.clear();
  }

  Future<void> _joinGroup(int groupId) async {
    setState(() => isLoading = true);
    final result = await ApiService.joinGroup(groupId);
    await _loadAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true ? "Đã gửi yêu cầu!" : result['message'] ?? "Lỗi"),
      backgroundColor: result['success'] == true ? Colors.green : Colors.orange,
    ));
  }

  Future<void> _handleInvitation(int? id, bool accept) async {
    if (id == null) return;
    setState(() => isLoading = true);
    final result = await ApiService.handleInvitation(id, accept);
    await _loadAll(); // TỰ ĐỘNG CHUYỂN SANG MÀN HÌNH NHÓM KHI CHẤP NHẬN
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true
          ? (accept ? "Đã tham gia nhóm thành công!" : "Đã từ chối lời mời")
          : result['message'] ?? "Thao tác thất bại"),
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _handleJoinRequest(int? groupId, int? requestId, bool accept) async {
    if (groupId == null || requestId == null) return;
    setState(() => isLoading = true);
    final result = await ApiService.handleJoinRequest(groupId, requestId, accept);
    await _loadAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true
          ? (accept ? "Đã chấp nhận thành viên!" : "Đã từ chối yêu cầu")
          : result['message'] ?? "Thao tác thất bại"),
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showInviteDialog() async {
    final searchCtrl = TextEditingController();
    List<dynamic> results = [];
    bool searching = true;
    final planId = _toInt(myGroup?['group_data']?['ID_KEHOACH']);
    if (planId == null) return;

    results = await ApiService.searchAvailableStudents(planId: planId, search: "");
    searching = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Mời thành viên"),
          content: SizedBox(
            width: double.maxFinite,
            height: 520,
            child: Column(children: [
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                    hintText: "Tìm MSSV/tên",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                onChanged: (val) async {
                  setStateDialog(() => searching = true);
                  results = await ApiService.searchAvailableStudents(planId: planId, search: val.trim());
                  setStateDialog(() => searching = false);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: searching
                    ? const Center(child: CircularProgressIndicator())
                    : results.isEmpty
                        ? const Center(child: Text("Không tìm thấy sinh viên nào"))
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (_, i) {
                              final sv = _safeMap(results[i]);
                              final user = _safeMap(sv['nguoidung'] ?? sv);
                              final maSV = sv['MA_DINHDANH'] ?? user['MA_DINHDANH'] ?? '';
                              final name = user['HODEM_VA_TEN'] ?? "Không tên";
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                                  title: Text(name),
                                  subtitle: Text("MSSV: $maSV"),
                                  trailing: ElevatedButton(
                                    onPressed: () async {
                                      final groupId = _toInt(myGroup?['group_data']?['ID_NHOM']);
                                      if (groupId == null) return;
                                      final res = await ApiService.inviteMember(groupId: groupId, maDinhDanh: maSV);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(res['success'] == true ? "Đã mời $name" : res['message'] ?? "Lỗi")));
                                      if (res['success'] == true) {
                                        Navigator.pop(context);
                                        _loadAll(); // reload để hiện lời mời mới
                                      }
                                    },
                                    child: const Text("Mời"),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))],
        ),
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> user, {bool isLeader = false}) {
    final name = user['HODEM_VA_TEN'] ?? "Không tên";
    final maSV = user['MA_DINHDANH'] ?? "Chưa có";
    return Card(
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: isLeader ? Colors.orange : Colors.deepPurple,
            child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("MSSV: $maSV"),
        trailing: isLeader ? const Chip(label: Text("Trưởng nhóm"), backgroundColor: Colors.orange) : null,
      ),
    );
  }

  // HIỂN THỊ YÊU CẦU XIN VÀO NHÓM
  Widget _buildJoinRequests() {
    if (joinRequests.isEmpty) {
      return Card(
        color: Colors.blueGrey.shade50,
        child: Padding(padding: EdgeInsets.all(20), child: Text("Không có yêu cầu nào", textAlign: TextAlign.center)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: joinRequests.length,
      itemBuilder: (_, i) {
        final req = _safeMap(joinRequests[i]);
        final user = _safeMap(req['nguoidung'] ?? req['sinhvien'] ?? {});
        final reqId = _toInt(req['ID_YEUCAU'] ?? req['id']);
        final groupId = _toInt(myGroup?['group_data']?['ID_NHOM']);

        final status = (req['TRANGTHAI'] ?? "Đang chờ").toString();
        final isPending = status == "Đang chờ";
        final isAccepted = status == "Chấp nhận";
        final isRejected = status == "Từ chối";

        Color cardColor = isAccepted ? Colors.green.shade50 : isRejected ? Colors.red.shade50 : Colors.yellow.shade50;
        String statusText = isAccepted ? "Đã chấp nhận" : isRejected ? "Đã từ chối" : "Đang chờ duyệt";
        IconData statusIcon = isAccepted ? Icons.check_circle : isRejected ? Icons.cancel : Icons.access_time;

        return Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAccepted ? Colors.green : isRejected ? Colors.red : Colors.orange,
              child: Text(user['HODEM_VA_TEN']?[0]?.toUpperCase() ?? "?"),
            ),
            title: Text(user['HODEM_VA_TEN'] ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("MSSV: ${user['MA_DINHDANH'] ?? 'N/A'}"),
              const SizedBox(height: 4),
              Row(children: [
                Icon(statusIcon, size: 16, color: isAccepted ? Colors.green[700] : isRejected ? Colors.red[700] : Colors.orange[700]),
                const SizedBox(width: 6),
                Text(statusText, style: TextStyle(color: isAccepted ? Colors.green[700] : isRejected ? Colors.red[700] : Colors.orange[700])),
              ]),
              if (req['LOINHAN'] != null) Text("Lời nhắn: ${req['LOINHAN']}", style: const TextStyle(fontStyle: FontStyle.italic)),
            ]),
            trailing: isPending && isLeader
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      onPressed: () => _handleJoinRequest(groupId, reqId, true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                      onPressed: () => _handleJoinRequest(groupId, reqId, false),
                    ),
                  ])
                : Icon(statusIcon, color: isAccepted ? Colors.green : Colors.red, size: 32),
          ),
        );
      },
    );
  }

  // HIỂN THỊ LỜI MỜI ĐÃ GỬI
  Widget _buildSentInvitations() {
    if (sentInvitations.isEmpty) {
      return Card(
        color: Colors.blueGrey.shade50,
        child: Padding(padding: EdgeInsets.all(20), child: Text("Chưa gửi lời mời nào", textAlign: TextAlign.center)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sentInvitations.length,
      itemBuilder: (_, i) {
        final inv = _safeMap(sentInvitations[i]);
        final user = _safeMap(inv['nguoiduocmoi'] ?? inv['nguoidung'] ?? {});

        final status = (inv['TRANGTHAI'] ?? "Đang chờ").toString();
        final isPending = status == "Đang chờ";
        final isAccepted = status == "Chấp nhận";
        final isRejected = status == "Từ chối" || status == "Đã hủy";
        final isExpired = inv['NGAY_HETHAN'] != null &&
            DateTime.tryParse(inv['NGAY_HETHAN'])!.isBefore(DateTime.now());

        Color cardColor = isAccepted
            ? Colors.green.shade50
            : isRejected || isExpired
                ? Colors.red.shade50
                : Colors.yellow.shade50;
        String statusText = isAccepted
            ? "Đã chấp nhận"
            : isRejected
                ? "Đã từ chối"
                : isExpired
                    ? "Hết hạn"
                    : "Đang chờ";
        IconData icon = isAccepted
            ? Icons.check_circle
            : isRejected || isExpired
                ? Icons.cancel
                : Icons.access_time;

        return Card(
          color: cardColor,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAccepted ? Colors.green : isRejected || isExpired ? Colors.red : Colors.orange,
              child: Text(user['HODEM_VA_TEN']?[0]?.toUpperCase() ?? "?"),
            ),
            title: Text(user['HODEM_VA_TEN'] ?? "Sinh viên", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("MSSV: ${user['MA_DINHDANH'] ?? 'N/A'} • $statusText"),
            trailing: Icon(icon, color: isAccepted ? Colors.green : Colors.red),
          ),
        );
      },
    );
  }

  // MÀN HÌNH KHI ĐÃ CÓ NHÓM
  Widget _buildMyGroup() {
    final group = _safeMap(myGroup?['group_data']);
    final membersRaw = _safeList(group['thanhviens']);
    final leaderId = _toInt(group['ID_NHOMTRUONG']);

    String planName = myGroup?['plan_detail']?['TEN_KEHOACH'] ??
        myGroup?['plan_detail']?['TEN_DOT'] ??
        "Chưa xác định";
    String topicName = "Chưa đăng ký đề tài";
    final detai = group['phancong_detai_nhom']?['detai'] ?? group['detai'];
    if (detai is Map && detai['TEN_DETAI'] != null) topicName = detai['TEN_DETAI'];

    Map<String, dynamic>? leaderUser;
    final members = <Map<String, dynamic>>[];
    for (var m in membersRaw) {
      final u = _safeMap(_safeMap(m)['nguoidung'] ?? m);
      if (_toInt(u['ID_NGUOIDUNG']) == leaderId || _toInt(u['ID_SINHVIEN']) == leaderId) {
        leaderUser = u;
      } else {
        members.add(u);
      }
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Thông tin nhóm
        Card(
            color: Colors.deepPurple.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(group['TEN_NHOM'] ?? "Nhóm của bạn",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 12),
                  Text("Đợt: $planName"),
                  const SizedBox(height: 6),
                  Text("Đề tài: $topicName",
                      style: TextStyle(
                          fontWeight: topicName.contains("Chưa") ? FontWeight.normal : FontWeight.bold,
                          color: topicName.contains("Chưa") ? Colors.grey[700] : Colors.green[700])),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await ApiService.leaveGroup();
                          await _loadAll();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok
                                  ? "Rời nhóm thành công"
                                  : "Bạn là trưởng nhóm, không thể rời!")));
                        },
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text("Rời nhóm"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent)),
                    Text("${members.length + (leaderUser != null ? 1 : 0)} / 4 thành viên",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ]))),

        const SizedBox(height: 30),
        const Text("Nhóm trưởng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        leaderUser != null ? _memberCard(leaderUser, isLeader: true) : const Text("Đang tải..."),

        const SizedBox(height: 30),
        const Text("Thành viên", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ...members.map((u) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _memberCard(u))),

        if (isLeader) ...[
          const SizedBox(height: 40),
          ElevatedButton.icon(
              onPressed: _showInviteDialog,
              icon: const Icon(Icons.person_add_alt_1, size: 32),
              label: const Text("MỜI THÀNH VIÊN MỚI"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
        ],

        // LỜI MỜI ĐÃ GỬI
        const SizedBox(height: 40),
        const Text("Lời mời đã gửi",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 12),
        _buildSentInvitations(),

        // YÊU CẦU XIN VÀO NHÓM
        const SizedBox(height: 40),
        const Text("Yêu cầu xin vào nhóm",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 12),
        _buildJoinRequests(),

        const SizedBox(height: 100),
      ]),
    );
  }

  // MÀN HÌNH KHI CHƯA CÓ NHÓM
  Widget _buildNoGroup() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
            color: Colors.red.shade50,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Text("Bạn chưa có nhóm",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _groupNameCtrl,
                      decoration: InputDecoration(
                          labelText: "Tên nhóm",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          filled: true)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedPlanId,
                    hint: const Text("Chọn đợt đồ án"),
                    items: plans
                        .map((p) => DropdownMenuItem(
                            value: _toInt(p['ID_KEHOACH']),
                            child: Text(p['TEN_DOT'] ?? "Đợt ${_toInt(p['ID_KEHOACH'])}")))
                        .toList(),
                    onChanged: (v) async {
                      setState(() => selectedPlanId = v);
                      if (v != null) {
                        setState(() => isLoading = true);
                        availableGroups = await ApiService.getAvailableGroups(v);
                        setState(() => isLoading = false);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      onPressed: _createGroup,
                      icon: const Icon(Icons.group_add),
                      label: const Text("Tạo nhóm mới"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                ]))),

        const SizedBox(height: 30),
        const Text("Nhóm đang tuyển thành viên", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        availableGroups.isEmpty
            ? const Card(child: Padding(padding: EdgeInsets.all(20), child: Text("Không có nhóm nào mở")))
            : ListView.builder(
                itemCount: availableGroups.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, i) {
                  final g = _safeMap(availableGroups[i]);
                  final gid = _toInt(g['ID_NHOM']);
                  final daGui = g['da_gui_yeu_cau'] == true;
                  return Card(
                      child: ListTile(
                    title: Text(g['TEN_NHOM'] ?? "Nhóm", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${g['SO_THANHVIEN_HIENTAI'] ?? 1}/4 thành viên"),
                    trailing: ElevatedButton(
                        onPressed: daGui || gid == null ? null : () => _joinGroup(gid!),
                        child: Text(daGui ? "Đã gửi" : "Xin vào")),
                  ));
                }),

        const SizedBox(height: 30),
        const Text("Lời mời vào nhóm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        invitations.isEmpty
            ? const Card(child: Padding(padding: EdgeInsets.all(20), child: Text("Không có lời mời nào")))
            : ListView.builder(
                itemCount: invitations.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, i) {
                  final inv = _safeMap(invitations[i]);
                  final nhom = _safeMap(inv['nhom'] ?? {});
                  final invId = _toInt(inv['ID_LOIMOI'] ?? inv['ID'] ?? inv['id']);

                  final status = (inv['TRANGTHAI'] ?? "Đang chờ").toString();
                  final isAccepted = status.contains("Chấp nhận") || status.contains("accepted");
                  final isRejected = status.contains("Từ chối") || status.contains("rejected");
                  final isExpired = inv['NGAY_HETHAN'] != null &&
                      DateTime.tryParse(inv['NGAY_HETHAN'])!.isBefore(DateTime.now());

                  Color cardColor = isAccepted
                      ? Colors.green.shade50
                      : isRejected || isExpired
                          ? Colors.red.shade50
                          : Colors.yellow.shade50;
                  String statusText = isAccepted
                      ? "Đã chấp nhận"
                      : isRejected
                          ? "Đã từ chối"
                          : isExpired
                              ? "Hết hạn"
                              : "Đang chờ";

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text((nhom['TEN_NHOM'] ?? "?")[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      title: Text(nhom['TEN_NHOM'] ?? "Nhóm mời bạn", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (inv['LOINHAN'] != null) Text("Lời nhắn: ${inv['LOINHAN']}"),
                        Text(statusText, style: TextStyle(color: isAccepted ? Colors.green[700] : Colors.red[700])),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (!isAccepted && !isRejected && !isExpired)
                          IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                              onPressed: () => _handleInvitation(invId, true)),
                        if (!isAccepted && !isRejected && !isExpired)
                          IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
                              onPressed: () => _handleInvitation(invId, false)),
                        if (isAccepted || isRejected || isExpired)
                          Icon(isAccepted ? Icons.check_circle : Icons.cancel,
                              color: isAccepted ? Colors.green : Colors.red, size: 36),
                      ]),
                    ),
                  );
                }),

        const SizedBox(height: 100),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGroup = myGroup?['has_group'] == true;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Quản lý nhóm đồ án"),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll)]),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasGroup
              ? _buildMyGroup()
              : _buildNoGroup(),
    );
  }
}