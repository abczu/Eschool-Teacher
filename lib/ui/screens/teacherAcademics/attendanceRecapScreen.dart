import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/data/repositories/auth/authRepository.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    final String url = "${Api.recapDownload}?"
        "school_id=${widget.schoolId}"
        "&token=${widget.token}"
        "&api_token=$apiToken"
        "&month=${widget.month}"
        "&year=${widget.year}"
        "&class_id=${widget.classId}"
        "&class_section_id=${widget.classSectionId}"
        "&$userParam"
        "&type=api"
        "&gm=1"
        "${widget.isDownload ? '&download=1' : ''}";

    debugPrint("[RecapScreen] Full URL: $url");
    debugPrint("[RecapScreen] Params: schoolId=${widget.schoolId}, classId=${widget.classId}, classSectionId=${widget.classSectionId}, month=${widget.month}, year=${widget.year}");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint("[RecapScreen] Loading started: $url");
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            debugPrint("[RecapScreen] Loading finished: $url");
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}, Code: ${error.errorCode}");
          },
        ),
      )
      ..loadRequest(
        Uri.parse(url),
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
        ],
      ),
    );
  }
}
