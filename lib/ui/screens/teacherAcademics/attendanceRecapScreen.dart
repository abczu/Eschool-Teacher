import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:get/get.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';

class AttendanceRecapScreen extends StatefulWidget {
  final int schoolId;
  final String token;
  final int month;
  final int year;
  final int classId;
  final int classSectionId;
  final bool isDownload;
  final int? teacherId; // Tambahkan ini

  const AttendanceRecapScreen({
    super.key,
    required this.schoolId,
    required this.token,
    required this.month,
    required this.year,
    required this.classId,
    required this.classSectionId,
    this.isDownload = false,
    this.teacherId, // Tambahkan ini
  });

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return AttendanceRecapScreen(
      schoolId: int.parse(arguments['schoolId'].toString()),
      token: arguments['token'],
      month: arguments['month'],
      year: arguments['year'],
      classId: arguments['classId'],
      classSectionId: arguments['classSectionId'],
      isDownload: arguments['isDownload'] ?? false,
      teacherId: arguments['teacherId'],
    );
  }

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _previewUrl = '';

  String _buildPreviewUrl(String userParam, String apiToken) {
    // Bangun URL via Uri agar token (mengandung "|") ter-encode dengan benar.
    // Mode preview (isDownload=false): TANPA download => backend balas HTML.
    // Mode unduh (isDownload=true): dengan download=true => PDF binary.
    final queryParams = <String, String>{
      'school_id': widget.schoolId.toString(),
      'token': widget.token,
      'api_token': apiToken,
      'month': widget.month.toString(),
      'year': widget.year.toString(),
      'class_id': widget.classId.toString(),
      'class_section_id': widget.classSectionId.toString(),
      'type': 'api',
      'gm': '1',
      if (widget.isDownload) 'download': 'true',
    };
    // userParam berbentuk "teacher_id=xx" / "staff_id=xx"
    final parts = userParam.split('=');
    if (parts.length == 2 && parts[0].isNotEmpty) {
      queryParams[parts[0]] = parts[1];
    }
    return Uri.parse(Api.recapDownload)
        .replace(queryParameters: queryParams)
        .toString();
  }

  void _loadPreview() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    _controller.loadRequest(
      Uri.parse(_previewUrl),
      headers: Api.headers(useAuthToken: true),
    );
  }

  @override
  void initState() {
    super.initState();

    final user = AuthRepository.getUserDetails();
    final bool isStaff = (user.staff != null && user.staff!.id != null) ||
        user.getRoles().toLowerCase().contains("staff");

    final String apiToken = widget.token.split("|").last;
    final String userParam = isStaff
        ? "staff_id=${user.staff?.id ?? user.id}"
        : "teacher_id=${user.teacher?.id ?? user.id}";

    _previewUrl = _buildPreviewUrl(userParam, apiToken);

    debugPrint("[RecapScreen] Full URL: $_previewUrl");
    debugPrint("[RecapScreen] Params: schoolId=${widget.schoolId}, classId=${widget.classId}, classSectionId=${widget.classSectionId}, month=${widget.month}, year=${widget.year}");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint("[RecapScreen] Loading started: $url");
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) async {
            debugPrint("[RecapScreen] Loading finished: $url");
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Fallback: longgarkan viewport backend agar user-scalable=yes,
            // sehingga pinch-zoom tetap jalan walau template masih maximum-scale=1.
            try {
              await _controller.runJavaScript(
                "(function(){var m=document.querySelector('meta[name=viewport]');"
                "if(m){m.setAttribute('content','width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes');}"
                "else{var m2=document.createElement('meta');m2.name='viewport';"
                "m2.content='width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';"
                "document.head.appendChild(m2);}})();",
              );
            } catch (_) {}
          },
          onHttpError: (HttpResponseError error) {
            debugPrint(
                "[RecapScreen] HTTP error: ${error.response?.statusCode} ${error.response?.uri}");
            if (mounted) {
              final code = error.response?.statusCode;
              setState(() {
                _isLoading = false;
                _hasError = true;
                if (code == 401) {
                  _errorMessage =
                      'Sesi habis (401). Silakan login ulang lalu coba lagi.';
                } else if (code == 403) {
                  _errorMessage =
                      'Anda tidak memiliki izin (403) untuk rekap ini.';
                } else if (code == 404) {
                  _errorMessage =
                      'Data rekap tidak ditemukan (404). Periksa kelas/bulan yang dipilih.';
                } else {
                  _errorMessage =
                      'Gagal memuat pratinjau (HTTP ${code ?? 'unknown'}).';
                }
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
                "WebView Error: ${error.description}, Code: ${error.errorCode}");
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage =
                    'Gagal memuat pratinjau: ${error.description}. Periksa koneksi / token sesi.';
              });
            }
          },
        ),
      );

    // Enable pinch-zoom di Android agar tabel lebar bisa di-zoom + digeser.
    // iOS mengikuti meta viewport (sudah dilonggarkan via JS di onPageFinished).
    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController).enableZoom(true);
    }

    _controller.loadRequest(
      Uri.parse(_previewUrl),
      headers: Api.headers(useAuthToken: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Utils.getTranslatedLabel(recapAttendanceSubjectKey)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_hasError && !_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPreview,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
