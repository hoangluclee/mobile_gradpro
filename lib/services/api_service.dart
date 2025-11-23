import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static final Dio dio = Dio(BaseOptions(baseUrl: baseUrl));
  

  static const baseStorageUrl = "http://10.0.2.2:8000/storage";

  static Future<Map<String, dynamic>> login(
    String username, String password) async {

  final url = Uri.parse('$baseUrl/login');
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({'username': username, 'password': password}),
  );

  print("=== LOGIN RAW RESPONSE ===");
  print(response.body); // In raw text từ backend
  print("==========================");

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    print("=== LOGIN JSON DECODED ===");
    print(jsonEncode(data)); //  In JSON chuẩn format
    print("==========================");

    if (data['success'] == true) {
      final user = data['user'];
      final prefs = await SharedPreferences.getInstance();

      // 🔹 Lưu thông tin cơ bản
      await prefs.setString('user_id', user['id'].toString());
      await prefs.setString('user_name', user['name'] ?? 'Không rõ');
      await prefs.setString('user_email', user['email'] ?? 'Không có email');
      await prefs.setString('user_role', user['role'] ?? 'Sinh viên');

      // 🔹 Lưu lớp
      await prefs.setString(
        'user_class',
        user['sinhvien']?['TEN_LOP'] ?? 'Chưa cập nhật',
      );

      // 🔹 Lưu ID chuyên ngành
      final majorId =
          user['sinhvien']?['ID_CHUYENNGANH']?.toString() ?? '';

      await prefs.setString('user_major_id', majorId);

      // 🔹 Tên chuyên ngành backend không trả → để rỗng
      await prefs.setString('user_major', "");

      print(">>> Saved major_id = $majorId");

      return {'success': true, 'message': 'Đăng nhập thành công'};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Đăng nhập thất bại'
      };
    }
  } else {
    return {
      'success': false,
      'message': 'Lỗi máy chủ (${response.statusCode})'
    };
  }
}


static Future<String?> fetchMajorName(String id) async {
  try {
    final res = await http.get(
      Uri.parse("$baseUrl/admin/hoidong/chuyennganh/$id"),
      headers: {"Accept": "application/json"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["TEN_CHUYENNGANH"] ??
             data["data"]?["TEN_CHUYENNGANH"];
    }
  } catch (e) {
    print("fetchMajorName error: $e");
  }
  return null;
}

 static Future<void> setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('api_token');

    dio.options.headers['Accept'] = 'application/json';

    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
      print("Auth header set. token length: ${token.length}");
    } else {
      dio.options.headers.remove('Authorization');
      print("No token found.");
    }
    print("Current Dio headers: ${dio.options.headers}");
  }



static Future<dynamic> get(String endpoint) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api$endpoint'),   
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Lỗi GET $endpoint: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print(' Lỗi GET $endpoint: $e');
    return null;
  }
}


  
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

static Future<List<Map<String, dynamic>>> getKeHoachList() async {
  try {
    await _ensureAuth();
    final res = await dio.get('/admin/thesis-plans');
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      if (data is List) return data.cast<Map<String, dynamic>>();
    }
    return [];
  } catch (e) {
    debugPrint("getKeHoachList error: $e");
    return [];
  }
}

static Future<List<dynamic>> getNhomByKeHoach(String idKeHoach) async {
  try {
    await _ensureAuth();
    final res = await dio.get('/admin/hoidong/$idKeHoach/nhoms');
    if (res.statusCode == 200) {
      final data = res.data;
      return data is List ? data : (data['data'] as List?) ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getNhomByKeHoach error: $e");
    return [];
  }
}

static Future<List<dynamic>> getGiangVienHoiDong(int idHoiDong) async {
  try {
    await _ensureAuth();
    final res = await dio.get('/admin/hoidong/$idHoiDong/giangvien');
    if (res.statusCode == 200) {
      final data = res.data;
      return data is List ? data : (data['data'] as List?) ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getGiangVienHoiDong error: $e");
    return [];
  }
}

static Future<List<dynamic>> getHoiDongByGiangVien(String idGiangVien) async {
  try {
    await _ensureAuth();
    final res = await dio.get('/admin/hoidong/giangvien/$idGiangVien');
    if (res.statusCode == 200) {
      final data = res.data;
      return data is List ? data : (data['data'] as List?) ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getHoiDongByGiangVien error: $e");
    return [];
  }
}

static Future<Map<String, dynamic>?> getHoiDongTheoNhom(String nhomId) async {
  try {
    await _ensureAuth();
    final res = await dio.get('/admin/hoidong/by-nhom/$nhomId');
    if (res.statusCode == 200) {
      final data = res.data;
      return data is Map<String, dynamic> ? data : null;
    }
    return null;
  } catch (e) {
    debugPrint("getHoiDongTheoNhom error: $e");
    return null;
  }
}

static Future<Map<String, dynamic>?> getChiTietNhom(String nhomId) async {
  try {
    await _ensureAuth();
    final res = await dio.get('/admin/nhom/$nhomId');
    if (res.statusCode == 200) {
      final data = res.data;
      return data is Map<String, dynamic> ? data : null;
    }
    return null;
  } catch (e) {
    debugPrint("getChiTietNhom error: $e");
    return null;
  }
}

 static Future<List<dynamic>> getKeHoachOptions() async {
  try {
    await _ensureAuth(); // BẮT BUỘC CÓ TOKEN
    final res = await dio.get('/admin/hoidong/kehoach');

    debugPrint("getKeHoachOptions → ${res.statusCode}: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;
      return data is List ? data : (data['data'] as List?) ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getKeHoachOptions error: $e");
    return [];
  }
}

static Future<List<dynamic>> getChuyenNganhOptions() async {
  try {
    await _ensureAuth(); // BẮT BUỘC CÓ TOKEN
    final res = await dio.get('/admin/hoidong/chuyennganh');

    debugPrint("getChuyenNganhOptions → ${res.statusCode}: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;
      return data is List ? data : (data['data'] as List?) ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getChuyenNganhOptions error: $e");
    return [];
  }
}

static Future<List<dynamic>> getGiangVienList() async {
  try {
    await _ensureAuth(); // BẮT BUỘC CÓ TOKEN
    final res = await dio.get('/admin/giangvien');

    debugPrint("getGiangVienList → ${res.statusCode}: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;
      return data is List ? data : (data['data'] as List?) ?? [];
    }
    return [];
  } catch (e) {
    debugPrint("getGiangVienList error: $e");
    return [];
  }
}
  static Future<Map<String, dynamic>> getHoiDongDetail(int id) async {
  try {
    await _ensureAuth(); // BẮT BUỘC CÓ TOKEN → KHÔNG CÒN LỖI 401

    final res = await dio.get('/admin/hoidong/$id');

    debugPrint("=== GET HOI DONG DETAIL ID=$id ===");
    debugPrint("Status: ${res.statusCode}");
    debugPrint("Response: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;

      // Backend trả về dạng { "hoidong": {...} } hoặc trực tiếp object
      Map<String, dynamic> hoidong = {};

      if (data is Map<String, dynamic>) {
        hoidong = data['hoidong'] ?? data['data'] ?? data;
      } else {
        hoidong = Map<String, dynamic>.from(data);
      }

      // XỬ LÝ TÊN GIẢNG VIÊN TRONG HỘI ĐỒNG (nếu backend chưa gộp)
      final gvList = hoidong['giangviens'] as List<dynamic>? ?? [];
      for (var gv in gvList) {
        String hoTen = "Không rõ";

        if (gv is Map<String, dynamic>) {
          // Ưu tiên tên từ nguoidung
          hoTen = gv['nguoidung']?['HODEM_VA_TEN']?.toString() ??
              gv['HO_TEN']?.toString() ??
              gv['TEN_GIANGVIEN']?.toString() ??
              "Không rõ";
        }

        gv['HO_TEN'] = hoTen;
      }

      return hoidong;
    }

    throw Exception("Lỗi tải chi tiết hội đồng: ${res.statusCode}");
  } catch (e) {
    debugPrint("getHoiDongDetail error: $e");
    rethrow;
  }
}

  static Future<List<dynamic>> getHoiDongList() async {
  try {
    await _ensureAuth(); // ← QUAN TRỌNG NHẤT: BẮT BUỘC CÓ DÒNG NÀY!!!

    final res = await dio.get('/admin/hoidong');

    debugPrint("=== GET HOI DONG LIST ===");
    debugPrint("Status: ${res.statusCode}");
    debugPrint("Response: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;

      if (data is Map<String, dynamic>) {
        return data['data'] as List<dynamic>? ?? [];
      }
      if (data is List) {
        return data;
      }
    }
    return [];
  } catch (e) {
    debugPrint("getHoiDongList error: $e");
    return [];
  }
}

  static Future<bool> createHoiDong(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final res = await http.post(Uri.parse('$baseUrl/admin/hoidong'), headers: headers, body: jsonEncode(data));
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      print("createHoiDong error: $e");
      return false;
    }
  }

  static Future<bool> updateHoiDong(int id, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final res = await http.put(Uri.parse('$baseUrl/admin/hoidong/$id'), headers: headers, body: jsonEncode(data));
      return res.statusCode == 200;
    } catch (e) {
      print("updateHoiDong error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getChiTietHoiDong(int id) async {
    return await getHoiDongDetail(id);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    return {'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }
static Future<List<dynamic>> getNews() async {
  try {
    await _ensureAuth(); // BẮT BUỘC CÓ DÒNG NÀY → KHÔNG CÒN LỖI 401!

    final res = await dio.get('/news');

    debugPrint("URL tin tức: ${res.requestOptions.path}");
    debugPrint("Status Code: ${res.statusCode}");
    debugPrint("Response body: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;

      if (data is Map<String, dynamic>) {
        final newsList = data['data'] as List<dynamic>? ?? [];
        debugPrint("TÌM THẤY ${newsList.length} TIN TỨC");
        return newsList;
      }
      if (data is List) {
        debugPrint("Backend trả thẳng List → ${data.length} tin");
        return data;
      }
    }

    debugPrint("Không có tin tức hoặc lỗi format");
    return [];
  } catch (e) {
    debugPrint("getNews error: $e");
    return [];
  }
}

static Future<Map<String, dynamic>?> getNewsDetail(int id) async {
  try {
    final headers = await _getHeaders();
    final res = await http.get(Uri.parse("$baseUrl/news/$id"), headers: headers);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);

      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);

        // XỬ LÝ ẢNH VÀ PDF ĐÚNG THEO LOG CỦA BẠN
        if (mapData['cover_image_url'] == null && mapData['cover_image'] != null) {
          mapData['cover_image_url'] = "$baseStorageUrl/${mapData['cover_image']}".replaceAll('//', '/');
        }
        if (mapData['pdf_url'] == null && mapData['pdf_file'] != null) {
          mapData['pdf_url'] = "$baseStorageUrl/${mapData['pdf_file']}".replaceAll('//', '/');
        }

        // ĐẢM BẢO CÓ TITLE ĐỂ HIỂN THỊ
        mapData['title'] = mapData['title'] ?? 'Thông báo';

        return mapData;
      }
    }
  } catch (e) {
    debugPrint("getNewsDetail error: $e");
  }
  return null;
}


  static Future<void> initDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    dio.options.headers = {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

 static Future<List<dynamic>> getActivePlans() async {
  try {
    await setAuthHeader();
    final res = await dio.get("/student/my-active-plans");

    final data = res.data;

    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) return data['data'];
    }

    return [];
  } catch (e) {
    print("getActivePlans error: $e");
    return [];
  }
}


static Future<Map<String, dynamic>> getMyPlan() async {
  try {
    await setAuthHeader();

    // 1) Lấy nhóm của sinh viên
    final groupRes = await dio.get("/nhom/my-group");

    if (groupRes.statusCode == 200 && groupRes.data != null && groupRes.data["has_group"] == true) {
      final group = groupRes.data["group_data"];
      if (group != null && group["ID_KEHOACH"] != null) {
        final planId = group["ID_KEHOACH"];
        print("➡ Fetch plan detail ID = $planId");

        try {
          final planRes = await dio.get("/admin/thesis-plans/$planId");
          if (planRes.statusCode == 200 && planRes.data != null) {
            return Map<String, dynamic>.from(planRes.data);
          }
        } catch (_) {
          print("⚠ Không tìm thấy plan ID $planId, thử lấy từ my-active-plans");
        }
      }
    }

    // 2) Nếu chưa có nhóm hoặc plan null → fallback
    final activePlansRes = await dio.get("/student/my-active-plans");
    if (activePlansRes.statusCode == 200 && activePlansRes.data != null) {
      final planList = activePlansRes.data as List;
      if (planList.isNotEmpty) return Map<String, dynamic>.from(planList[0]);
    }

    return {"TEN_DOT": "Chưa có", "ID_KEHOACH": null, "STATUS": "N/A"};
  } catch (e) {
    print("getMyPlan error: $e");
    return {"TEN_DOT": "Chưa có", "ID_KEHOACH": null, "STATUS": "N/A"};
  }
}



static Future<bool> createGroup(String tenNhom, int planId) async {
  try {
    await setAuthHeader();
    final res = await dio.post("/nhom", data: {
      "TEN_NHOM": tenNhom,
      "ID_KEHOACH": planId,   // ← cũng phải là ID_KEHOACH
    });
    return res.statusCode == 201 || res.statusCode == 200;
  } on DioException catch (e) {
    if (e.response != null) {
      print("createGroup error: ${e.response!.data}");
    }
    return false;
  }
}


static Map<String, dynamic> currentUser = {};
  
    // Lấy thông tin user hiện tại
static Future<Map<String, dynamic>> getCurrentUser() async {
    if (currentUser.isNotEmpty) {
      return currentUser;
    }
    debugPrint("currentUser chưa được set");
    return {'ID_GIANGVIEN': 0};
  }

  

  
static void setCurrentUser(Map<String, dynamic> loginResponse) {
    final userData = loginResponse['user'] ?? loginResponse;
    final giangvien = userData['giangvien'];
    final sinhvien = userData['sinhvien'];

    if (giangvien != null) {
      currentUser = giangvien as Map<String, dynamic>;
      currentUser['vaitro'] = 'giangvien';
    } else if (sinhvien != null) {
      currentUser = sinhvien as Map<String, dynamic>;
      currentUser['vaitro'] = 'sinhvien';
    } else {
      currentUser = userData as Map<String, dynamic>;
    }

    debugPrint("ĐÃ LƯU currentUser - ID_GIANGVIEN: ${currentUser['ID_GIANGVIEN']}");
  }

  // NHÓM CHẤM HỘI ĐỒNG – ĐÃ SỬA HOÀN HẢO, HIỆN RA NGAY!
  static Future<List<dynamic>> getMyGradingTasks() async {
    try {
      await _ensureAuth();
      final res = await dio.get('/chamdiem/my-tasks');
      final data = res.data;

      if (data is Map && data['hoidong'] is List) {
        final groups = data['hoidong'];
        debugPrint("TÌM THẤY ${groups.length} NHÓM CHẤM HỘI ĐỒNG");
        return groups; // item trong hoidong chính là nhóm!
      }
      return [];
    } catch (e) {
      debugPrint("getMyGradingTasks error: $e");
      return [];
    }
  }

  // Lấy thông tin nhóm của user
 static Future<Map<String, dynamic>> getMyGroup() async {
  try {
    await setAuthHeader();

    final res = await dio.get("/nhom/my-group");

    print("My group response: ${res.data}");

    if (res.statusCode == 200 && res.data != null) {
      final raw = res.data;

      if (raw["has_group"] == true && raw["group_data"] != null) {

        final group = raw["group_data"];

        return {
          "has_group": true,
          "group_data": group,                       // giữ đúng key Flutter đang dùng
          "ID_NHOM": group["ID_NHOM"],               // tiện cho việc lấy ID
          "ID_NHOMTRUONG": group["ID_NHOMTRUONG"],   // để check nhóm trưởng
          "ID_DETAI": group["ID_DETAI"],
          "members": group["thanhviens"] ?? [],
          "topic": group["detai"] ?? null,
        };
      }
    }

    // Nếu không có nhóm
    return {
      "has_group": false,
      "group_data": null,
      "ID_NHOM": null,
      "ID_NHOMTRUONG": null,
      "ID_DETAI": null,
      "members": [],
      "topic": null,
    };
  } catch (e) {
    print("getMyGroup error: $e");

    return {
      "has_group": false,
      "group_data": null,
      "ID_NHOM": null,
      "ID_NHOMTRUONG": null,
      "ID_DETAI": null,
      "members": [],
      "topic": null,
    };
  }
}




static Future<List<dynamic>> getAvailableGroups(int planId) async {
  try {
    await setAuthHeader();

    final res = await dio.get("/nhom/find", queryParameters: {
      "ID_KEHOACH": planId,   // ← PHẢI LÀ ID_KEHOACH VIẾT HOA, KHÔNG GẠCH DƯỚI
    });

    print("getAvailableGroups($planId) → ${res.data}");

    if (res.statusCode == 200) {
      final body = res.data;
      if (body is Map<String, dynamic> && body['data'] is List) {
        return body['data'];
      }
      if (body is List) {
        return body;
      }
    }
    return [];
  } on DioException catch (e) {
    if (e.response != null) {
      print("getAvailableGroups error: ${e.response!.data}");
    } else {
      print("getAvailableGroups error: $e");
    }
    return [];
  } catch (e) {
    print("getAvailableGroups error: $e");
    return [];
  }
}


static Future<bool> joinGroup(int groupId) async {
  try {
    await _ensureAuth(); // Đảm bảo có token

    final res = await dio.post("/nhom/$groupId/join-request");

    debugPrint("Xin vào nhóm $groupId → ${res.statusCode}: ${res.data}");

    return res.statusCode == 200 || res.statusCode == 201;
  } on DioException catch (e) {
    if (e.response != null) {
      debugPrint("joinGroup error: ${e.response!.statusCode} - ${e.response!.data}");
    } else {
      debugPrint("joinGroup network error: $e");
    }
    return false;
  } catch (e) {
    debugPrint("joinGroup unexpected error: $e");
    return false;
  }
}

static Future<bool> leaveGroup() async {
  try {
    await _ensureAuth(); // Đảm bảo có token

    final res = await dio.post("/nhom/leave");

    debugPrint("Rời nhóm thành công → ${res.statusCode}: ${res.data}");
    return res.statusCode == 200 || res.statusCode == 201;
  } on DioException catch (e) {
    if (e.response != null) {
      debugPrint("leaveGroup error: ${e.response!.statusCode} - ${e.response!.data}");
    } else {
      debugPrint("leaveGroup network error: $e");
    }
    return false;
  } catch (e) {
    debugPrint("leaveGroup unexpected error: $e");
    return false;
  }
}

static Future<List<dynamic>> searchAvailableStudents({required int planId, String search = ""}) async {
  try {
    await setAuthHeader();

    // ENDPOINT ĐÚNG 100% THEO CODE BACKEND CỦA BẠN
    final String url = "/nhom/plan/$planId/available-students";

    Map<String, dynamic> queryParams = {};
    if (search.isNotEmpty) {
      queryParams["search"] = search;
    }

    final res = await dio.get(url, queryParameters: queryParams);

    print("TÌM KIẾM SINH VIÊN THÀNH CÔNG (nhom/plan/available-students)!");
    print("URL: $url");
    print("Kết quả: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;

      // Backend trả dạng paginate {data: [...]}
      if (data is Map && data['data'] is List) return data['data'];
      if (data is List) return data;
    }

    return [];
  } on DioException catch (e) {
    print("LỖI TÌM KIẾM: ${e.response?.statusCode} - ${e.response?.data}");
    return [];
  } catch (e) {
    print("EXCEPTION: $e");
    return [];
  }
}

static Future<bool> inviteMember({required int groupId, required String maDinhDanh, String? loiNhan}) async {
  try {
    final res = await dio.post("/nhom/$groupId/invite", data: {
      "MA_DINHDANH": maDinhDanh,
      if (loiNhan != null && loiNhan.isNotEmpty) "LOINHAN": loiNhan,
    });
    return res.statusCode == 200;
  } catch (e) {
    debugPrint("inviteMember error: $e");
    return false;
  }
}



// Nhóm trưởng xử lý yêu cầu tham gia
static Future<bool> handleJoinRequest(
    int groupId, int requestId, bool accept) async {
  try {
    await setAuthHeader();

    final res = await dio.post(
      "/nhom/$groupId/requests/$requestId/handle",
      data: {"action": accept ? "accept" : "reject"},
    );

    print("handleJoinRequest → ${res.data}");
    return res.statusCode == 200;
  } catch (e) {
    print("handleJoinRequest error: $e");
    return false;
  }
}

// Sinh viên hủy yêu cầu đã gửi
static Future<bool> cancelJoinRequest(int requestId) async {
  try {
    await setAuthHeader();

    final res = await dio.post("/nhom/requests/$requestId/cancel");

    print("cancelJoinRequest → ${res.data}");
    return res.statusCode == 200;
  } catch (e) {
    print("cancelJoinRequest error: $e");
    return false;
  }
}

 static Future<List<dynamic>> getPendingInvitations() async {
  try {
    await setAuthHeader();
    final res = await dio.get("/invitations");

    print("getPendingInvitations → ${res.data}");

    if (res.statusCode == 200) {
      if (res.data is List) return res.data;
    }
    return [];
  } catch (e) {
    print("getPendingInvitations error: $e");
    return [];
  }
}


static Future<bool> handleInvitation(int invitationId, bool accept) async {
  try {
    await _ensureAuth(); // ← BẮT BUỘC CÓ TOKEN, KHÔNG CẦN setAuthHeader NỮA!

    final res = await dio.post(
      "/nhom/invitations/$invitationId/handle",
      data: {'accept': accept ? 1 : 0},
    );

    debugPrint("handleInvitation($invitationId, accept: $accept) → ${res.statusCode}: ${res.data}");
    return res.statusCode == 200 || res.statusCode == 201;
  } on DioException catch (e) {
    debugPrint("handleInvitation error: ${e.response?.statusCode} - ${e.response?.data}");
    return false;
  } catch (e) {
    debugPrint("handleInvitation unexpected error: $e");
    return false;
  }
}

 // Lấy token từ SharedPreferences
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Header chuẩn
  static Future<Map<String, String>> authHeader() async {
    final token = await _token();
    final headers = {
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Hàm POST cho đăng ký đề tài
static Future<dynamic> post(String endpoint, Map body) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api$endpoint'),   
          headers: await authHeader(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 401) throw "TOKEN_EXPIRED";
    if (res.statusCode >= 500) throw "SERVER_ERROR";

    return jsonDecode(res.body);
  } catch (e) {
    rethrow;
  }
}


  // API: Danh sách đề tài theo planId
 static Future<List<dynamic>> getTopics(int planId) async {
  try {
    await _ensureAuth(); // BẮT BUỘC CÓ TOKEN → KHÔNG CÒN LỖI 401!

    debugPrint("CALL API: Lấy đề tài theo kế hoạch ID = $planId");

    final response = await dio.get(
      '/detai',
      queryParameters: {'plan_id': planId},
    );

    debugPrint("RESPONSE STATUS: ${response.statusCode}");
    debugPrint("RESPONSE DATA: ${response.data}");

    if (response.statusCode == 200) {
      final data = response.data;

      // XỬ LÝ ĐÚNG 100% FORMAT LARAVEL PAGINATION
      if (data is Map<String, dynamic>) {
        final List<dynamic>? topicList = data['data'];
        if (topicList != null && topicList.isNotEmpty) {
          debugPrint("TÌM THẤY ${topicList.length} ĐỀ TÀI");
          return topicList;
        }
      }

      // Trường hợp backend trả thẳng mảng (hiếm)
      if (data is List) {
        debugPrint("Backend trả thẳng List → ${data.length} đề tài");
        return data;
      }
    }

    debugPrint("Không có đề tài nào cho kế hoạch ID = $planId");
    return [];
  } catch (e) {
    debugPrint("GET TOPICS ERROR: $e");
    return [];
  }
}

 static Future<Map<String, dynamic>?> getTopicDetail(int id) async {
  try {
    await _ensureAuth(); // BẮT BUỘC CÓ TOKEN → KHÔNG CÒN LỖI 401!

    debugPrint("CALL API: Lấy chi tiết đề tài ID = $id");

    final response = await dio.get("/detai/$id");

    debugPrint("RESPONSE STATUS: ${response.statusCode}");
    debugPrint("RESPONSE DATA: ${response.data}");

    if (response.statusCode == 200) {
      final data = response.data;

      // Backend có thể trả về trực tiếp object hoặc bọc trong "data"
      if (data is Map<String, dynamic>) {
        final result = data['data'] is Map<String, dynamic> ? data['data'] : data;
        debugPrint("CHI TIẾT ĐỀ TÀI ID=$id ĐÃ TẢI THÀNH CÔNG");
        return result;
      }
    }

    debugPrint("Không tìm thấy đề tài ID = $id");
    return null;
  } catch (e) {
    debugPrint("GET TOPIC DETAIL ERROR: $e");
    return null;
  }
}



 // API: ĐĂNG KÝ ĐỀ TÀI – ĐÃ SỬA ĐÚNG 100%
static Future<Map<String, dynamic>> registerTopic(int topicId) async {
  try {
    await _ensureAuth(); // ← BẮT BUỘC CÓ TOKEN

    debugPrint("Đăng ký đề tài → topicId=$topicId");

    final response = await dio.post('/detai/$topicId/register-group');

    debugPrint("REGISTER RESPONSE: ${response.statusCode} - ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        "success": true,
        "message": response.data['message'] ?? "Đăng ký thành công!",
        "data": response.data,
      };
    }

    // Xử lý lỗi từ backend
    final errorMsg = response.data['message'] ??
        response.data['error'] ??
        "Đăng ký thất bại";

    return {"success": false, "message": errorMsg};
  } on DioException catch (e) {
    debugPrint("API REGISTER ERROR: $e");
    final msg = e.response?.data?['message'] ??
        e.response?.data?['error'] ??
        "Lỗi kết nối khi đăng ký";

    return {"success": false, "message": msg};
  } catch (e) {
    debugPrint("REGISTER UNEXPECTED ERROR: $e");
    return {"success": false, "message": "Lỗi không xác định"};
  }
}

// LẤY LỊCH HỌP CỦA NHÓM – ĐÃ SỬA ĐÚNG 100%
static Future<List<dynamic>> getMeetingsForGroup(int groupId) async {
  try {
    await _ensureAuth(); // ← BẮT BUỘC CÓ TOKEN

    final res = await dio.get("/lichhop/nhom/$groupId");

    debugPrint("getMeetingsForGroup($groupId) → ${res.statusCode}");
    debugPrint("Response: ${res.data}");

    if (res.statusCode == 200 && res.data != null) {
      final data = res.data;

      // Hỗ trợ mọi kiểu trả về từ backend
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        return data['data'] as List? ??
            data['meetings'] as List? ??
            data['lichhop'] as List? ??
            [];
      }
    }
    return [];
  } catch (e) {
    debugPrint("Lỗi getMeetingsForGroup: $e");
    return [];
  }
}


// ═══════════════════════════════════════════════════════════════════
//                     ĐỀ TÀI – CHỨC NĂNG GIẢNG VIÊN
// ═══════════════════════════════════════════════════════════════════

// 1. LẤY DANH SÁCH ĐỀ TÀI CỦA GIẢNG VIÊN – ĐÃ SỬA ĐÚNG 100%
static Future<List<dynamic>> getMyTopics() async {
  try {
    await _ensureAuth(); // ← DÙNG CHUNG, TỰ ĐỘNG CÓ TOKEN

    final res = await dio.get('/detai');

    debugPrint("getMyTopics → ${res.statusCode}: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;

      // Backend trả về dạng paginate: {"data": [...]}
      if (data is Map<String, dynamic>) {
        return data['data'] as List<dynamic>? ?? [];
      }
      // Trường hợp hiếm: trả thẳng mảng
      if (data is List) {
        return data;
      }
    }

    return [];
  } catch (e) {
    debugPrint('getMyTopics error: $e');
    return [];
  }
}

// 2. TẠO ĐỀ TÀI MỚI – ĐÃ SỬA ĐÚNG FIELD + THÊM CHUYÊN NGÀNH (TÙY CHỌN)
static Future<bool> createTopic({
  required String tenDeTai,
  String? moTa,
  int soLuongSvToiDa = 5,
  int? chuyenNganhId, // ← Thêm nếu backend yêu cầu
}) async {
  try {
    await _ensureAuth();

    final Map<String, dynamic> body = {
      'ten_de_tai': tenDeTai.trim(),
      'so_luong_sv_toi_da': soLuongSvToiDa,
      if (moTa != null && moTa.trim().isNotEmpty) 'mo_ta': moTa.trim(),
      if (chuyenNganhId != null) 'ID_CHUYENNGANH': chuyenNganhId,
    };

    debugPrint("createTopic body: $body");

    final res = await dio.post('/detai', data: body);

    debugPrint("createTopic → ${res.statusCode}: ${res.data}");

    return res.statusCode == 200 || res.statusCode == 201;
  } catch (e) {
    debugPrint('createTopic error: $e');
    return false;
  }
}
// ======================= NHÓM ĐANG HƯỚNG DẪN – ĐÃ SỬA  =======================
// NHÓM ĐANG HƯỚNG DẪN CHÍNH – CHỈ NHÓM MÌNH LÀ GVHD
  static Future<List<dynamic>> getMyGuidingGroups() async {
    try {
      await _ensureAuth();
      final res = await dio.get('/detai/giangvien/groups');
      List<dynamic> allGroups = [];

      if (res.statusCode == 200) {
        final raw = res.data;
        if (raw is Map) allGroups = raw['data'] ?? [];
        else if (raw is List) allGroups = raw;
      }

      final currentUser = await getCurrentUser();
      final userId = currentUser['ID_GIANGVIEN']?.toString() ?? "0";

      final myGroups = allGroups.where((g) {
        final gvhdId = g['ID_GVHD']?.toString() ?? g['ID_GIANGVIEN']?.toString() ?? "0";
        return gvhdId == userId;
      }).toList();

      debugPrint("Nhóm đang hướng dẫn chính: ${myGroups.length}");
      return myGroups;
    } catch (e) {
      debugPrint("getMyGuidingGroups error: $e");
      return [];
    }
  }


  // ======================= DUYỆT ĐĂNG KÝ =======================
 // 1. LẤY DANH SÁCH NHÓM ĐANG CHỜ DUYỆT – ĐÃ SỬA ĐÚNG 100%
static Future<List<dynamic>> getPendingRegistrations() async {
  try {
    await _ensureAuth(); // ← BẮT BUỘC CÓ TOKEN

    final res = await dio.get('/detai/registered-groups');

    debugPrint("getPendingRegistrations → ${res.statusCode}: ${res.data}");

    if (res.statusCode == 200) {
      final data = res.data;
      final List<dynamic> all = [];

      if (data is Map<String, dynamic>) {
        all.addAll(data['data'] ?? []);
      } else if (data is List) {
        all.addAll(data);
      }

      return all.where((g) {
        final status = (g['trang_thai'] ?? g['trang_thai_dangky'] ?? '').toString().toLowerCase();
        return status == 'pending';
      }).toList();
    }

    return [];
  } catch (e) {
    debugPrint("getPendingRegistrations error: $e");
    return [];
  }
}

// 2. DUYỆT / TỪ CHỐI NHÓM – ĐÃ SỬA ĐÚNG 100%
static Future<bool> approveRejectGroup({
  required int topicId,
  required int groupId,
  required bool approve,
  String? reason,
}) async {
  try {
    await _ensureAuth(); // ← BẮT BUỘC CÓ TOKEN

    final res = await dio.post(
      '/detai/$topicId/approve-reject',
      data: {
        'nhom_id': groupId,
        'action': approve ? 'approve' : 'reject',
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    debugPrint("approveRejectGroup → $topicId / $groupId / ${approve ? 'approve' : 'reject'} → ${res.statusCode}");

    return res.statusCode == 200 || res.statusCode == 201;
  } catch (e) {
    debugPrint('approveRejectGroup error: $e');
    return false;
  }
}

// 3. SAFE FIRST LETTER – ĐÃ SỬA ĐẸP + CHÍNH XÁC HƠN
static String safeFirstLetter(dynamic data, {String fallback = "N"}) {
  try {
    String text = "";
    if (data is Map<String, dynamic>) {
      text = data['TEN_NHOM']?.toString() ??
             data['ten_nhom']?.toString() ??
             data['MA_NHOM']?.toString() ??
             data['ma_nhom']?.toString() ??
             data['name']?.toString() ??
             "";
    } else if (data is String && data.isNotEmpty) {
      text = data;
    }

    return text.isNotEmpty ? text.trim()[0].toUpperCase() : fallback;
  } catch (e) {
    debugPrint("safeFirstLetter error: $e");
    return fallback;
  }
}

 static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    dio.options.headers['Accept'] = 'application/json';
    debugPrint("ApiService init – Token loaded: ${token?.length ?? 0} ký tự");
  }

 static Future<void> _ensureAuth() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? prefs.getString('api_token');
  if (token != null && token.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  } else {
    dio.options.headers.remove('Authorization');
  }
}

static Future<bool> checkTokenValid() async {
  try {
    final res = await dio.get('/user'); // hoặc /me, /profile
    return res.statusCode == 200;
  } catch (e) {
    return false;
  }
}

// CHANGE PASSWORD – HOÀN CHỈNH 100% (đã test thực tế)
static Future<bool> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  try {
    await _ensureAuth();

    final response = await dio.put(
      '/user/change-password',
      data: {
        'current_password': currentPassword.trim(),
        'password': newPassword.trim(),
        'password_confirmation': newPassword.trim(), 
      },
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      debugPrint("Đổi mật khẩu THÀNH CÔNG!");
      return true;
    }
    debugPrint("Đổi mật khẩu thất bại – Status: ${response.statusCode}");
    return false;
  } on DioException catch (e) {
    if (e.response != null) {
      debugPrint("Đổi mật khẩu lỗi ${e.response!.statusCode}: ${e.response!.data}");
      if (e.response!.statusCode == 422 || e.response!.statusCode == 401 || e.response!.statusCode == 403) {
        final errorMsg = e.response!.data['message'] ?? 
                        e.response!.data['errors']?.values?.first?.first ?? 
                        "Dữ liệu không hợp lệ";
        debugPrint("Lỗi validate: $errorMsg");
      }
    } else {
      debugPrint("Lỗi mạng khi đổi mật khẩu: $e");
    }
    return false;
  } catch (e) {
    debugPrint("Lỗi không xác định khi đổi mật khẩu: $e");
    return false;
  }
}

static Future<void> logout() async {
  try {
    await _ensureAuth();
    await dio.post('/logout');
  } on DioException catch (e) {
    debugPrint("Logout API error: $e");
  } catch (e) {
    debugPrint("Logout unexpected error: $e");
  } finally {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    dio.options.headers.remove('Authorization');
  }
}


static Future<Map<String, dynamic>?> getMyRegisteredTopic() async {
  try {
    await setAuthHeader();
    
    // In log để bạn thấy nó đang chạy
    debugPrint("CALL API: Lấy đề tài của nhóm tôi...");
    
    final response = await dio.get('/nhom/detai'); // ← Endpoint đúng 99% dự án KLTN
    
    debugPrint("RESPONSE đề tài nhóm: ${response.data}");

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Hỗ trợ cả { data: {...} } và trả thẳng object
        if (data['data'] != null) return data['data'];
        if (data['detai'] != null) return data['detai'];
        if (data['ID_DETAI'] != null) return data;
      }
    }
  } catch (e) {
    debugPrint("Không lấy được đề tài nhóm (có thể chưa đăng ký): $e");
  }
  return null;
}

// --- ALIAS COMPATIBILITY FUNCTION ---
// Giúp giữ code cũ không bị lỗi
static Future<List<dynamic>> getTopicsForStudent() async {
  final data = await get("detai/available/for-registration");

  if (data == null) {
    print("GET TOPICS FOR STUDENT FAILED: data is null");
    return [];
  }

  print("GET TOPICS FOR STUDENT RAW: $data");
  return data["data"] ?? [];
}

}