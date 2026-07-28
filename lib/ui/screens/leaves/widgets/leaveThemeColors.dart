import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Warna tema maroon untuk halaman pengajuan cuti (Apply Leave)
const Color maroonPrimary = Color(0xFF8B1F41);
const Color maroonLight = Color(0xFFAC3B5C);
const Color maroonDark = Color(0xFF6A0F2A);
const Color accentColor = Color(0xFFF5EBE0);

Color get bgColor => Get.context != null && Theme.of(Get.context!).brightness == Brightness.dark
    ? Theme.of(Get.context!).scaffoldBackgroundColor
    : const Color(0xFFFAF6F2);

Color get cardColor => Get.context != null && Theme.of(Get.context!).brightness == Brightness.dark
    ? Theme.of(Get.context!).cardColor
    : Colors.white;

Color get textDarkColor => Get.context != null && Theme.of(Get.context!).brightness == Brightness.dark
    ? Colors.white
    : const Color(0xFF2D2D2D);

Color get textMediumColor => Get.context != null && Theme.of(Get.context!).brightness == Brightness.dark
    ? Colors.white70
    : const Color(0xFF717171);

Color get borderColor => Get.context != null && Theme.of(Get.context!).brightness == Brightness.dark
    ? Colors.white24
    : const Color(0xFFE8E8E8);

Color get leavePrimaryColor => Get.context != null && Theme.of(Get.context!).brightness == Brightness.dark
    ? const Color(0xFFE53935)
    : maroonPrimary;
