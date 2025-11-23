import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doancunhan/services/api_service.dart';

class EditHoiDongScreen extends StatefulWidget {
  final Map<String, dynamic>? hoidong;

  const EditHoiDongScreen({super.key, this.hoidong});

  @override
  State<EditHoiDongScreen> createState() => _EditHoiDongScreenState();
}

class _EditHoiDongScreenState extends State<EditHoiDongScreen> {
  final _formKey = GlobalKey<FormState>();

  final tenController = TextEditingController();
  final phongController = TextEditingController();
  final ngayController = TextEditingController();
  final gioController = TextEditingController();

  String? loai;
  int? idKeHoach;
  int? idChuyenNganh;

  bool isLoading = false;
  List<dynamic> keHoachs = [];
  List<dynamic> chuyenNganhs = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();

    if (widget.hoidong != null) {
      final hd = widget.hoidong!;
      tenController.text = hd['TEN_HOIDONG'] ?? '';
      phongController.text = hd['PHONG'] ?? '';
      ngayController.text = hd['NGAY_BAOCAO'] ?? '';
      gioController.text = hd['GIO_BAOCAO'] ?? '';
      loai = hd['LOAI'];
      idKeHoach = hd['ID_KEHOACH'];
      idChuyenNganh = hd['ID_CHUYENNGANH'];
    }
  }

  Future<void> _loadOptions() async {
    try {
      final kehoach = await ApiService.getKeHoachOptions();
      final cn = await ApiService.getChuyenNganhOptions();
      setState(() {
        keHoachs = kehoach;
        chuyenNganhs = cn;
      });
    } catch (e) {
      print("❌ load options error: $e");
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final data = {
      'TEN_HOIDONG': tenController.text.trim(),
      'LOAI': loai,
      'ID_KEHOACH': idKeHoach,
      'ID_CHUYENNGANH': idChuyenNganh,
      'NGAY_BAOCAO':
          ngayController.text.isNotEmpty ? ngayController.text : null,
      'GIO_BAOCAO': gioController.text.isNotEmpty ? gioController.text : null,
      'PHONG': phongController.text.trim(),
    };

    bool success = false;
    if (widget.hoidong == null) {
      success = await ApiService.createHoiDong(data);
    } else {
      success =
          await ApiService.updateHoiDong(widget.hoidong!['ID_HOIDONG'], data);
    }

    setState(() => isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          content: Text(widget.hoidong == null
              ? '✅ Thêm hội đồng thành công!'
              : '✅ Cập nhật hội đồng thành công!'),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('❌ Lưu thất bại!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.hoidong != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo.shade600,
        title: Text(
          isEdit ? 'Chỉnh sửa hội đồng' : 'Thêm hội đồng',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: tenController,
                          decoration: const InputDecoration(
                            labelText: 'Tên hội đồng',
                            prefixIcon: Icon(Icons.group),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Không được để trống'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Loại hội đồng',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          value: loai,
                          items: const [
                            DropdownMenuItem(
                                value: 'hoidong', child: Text('Hội đồng')),
                            DropdownMenuItem(
                                value: 'phanbien', child: Text('Phản biện')),
                          ],
                          onChanged: (v) => setState(() => loai = v),
                          validator: (v) =>
                              v == null ? 'Chọn loại hội đồng' : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Kế hoạch khóa luận',
                            prefixIcon: Icon(Icons.event),
                            border: OutlineInputBorder(),
                          ),
                          value: idKeHoach,
                          items: keHoachs
                              .map<DropdownMenuItem<int>>((e) =>
                                  DropdownMenuItem<int>(
                                    value: e['ID_KEHOACH'] as int,
                                    child: Text(e['TEN_DOT'] ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => idKeHoach = v),
                          validator: (v) =>
                              v == null ? 'Chọn kế hoạch' : null,
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Chuyên ngành',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          value: idChuyenNganh,
                          items: chuyenNganhs
                              .map<DropdownMenuItem<int>>((e) =>
                                  DropdownMenuItem<int>(
                                    value: e['ID_CHUYENNGANH'] as int,
                                    child: Text(e['TEN_CHUYENNGANH'] ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => idChuyenNganh = v),
                          validator: (v) =>
                              v == null ? 'Chọn chuyên ngành' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: phongController,
                          decoration: const InputDecoration(
                            labelText: 'Phòng báo cáo',
                            prefixIcon: Icon(Icons.meeting_room),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: ngayController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Ngày báo cáo',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              ngayController.text =
                                  DateFormat('yyyy-MM-dd').format(date);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: gioController,
                          decoration: const InputDecoration(
                            labelText: 'Giờ báo cáo (hh:mm)',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 28),

                        ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save),
                          label:
                              Text(isEdit ? 'Cập nhật' : 'Thêm mới'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
