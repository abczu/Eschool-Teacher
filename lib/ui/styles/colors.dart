import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:flutter/material.dart';

//Replace these colors accoridng to ui
Color primaryColor = const Color(0xffd22f3c);
Color secondaryColor = const Color(0xff6d0205);
Color pageBackgroundColor = const Color(0xffF7F9FF);
Color backgroundColor = const Color(0xffFFFFFF);
Color errorColor = const Color(0xffBA1A1A);
Color tertiaryColor =
    const Color(0xffEBEEF3); //Border color define in design style

// Warna untuk Tema Gelap (Spotify Style Premium)
const Color darkMainBackgroundColor = Color(0xFF121212); // Deep Charcoal
const Color darkCardBackgroundColor = Color(0xFF1E1E1E); // Opsional jika tidak pakai glass
const Color darkBottomNavBackgroundColor = Color(0xFF161616);
const Color darkPrimaryColor = Color(0xFFFF3D60); // Vibrant Pinkish Red
const Color darkSecondaryColor = Color(0xFFE53935);
const Color darkTextPrimaryColor = Color(0xFFFFFFFF);
const Color darkTextSecondaryColor = Color(0xFFB3B3B3);
const Color darkUnselectedIconColor = Color(0xFF757575);
const Color darkHeaderGradientColor = Color(0xFF4A0E17);
const Color darkGlassColor = Color(0x08FFFFFF); // Putih transparan 3% (0.03 * 255 = 7.6 ~ 0x08)
const Color darkGlassBorderColor = Color(0x14FFFFFF); // Putih transparan 8% (0.08 * 255 = 20.4 ~ 0x14)


CustomColors customColorsExtension = const CustomColors(
  redColor: Color(0xffBA1A1A),
  successColor: Color(0xff56B35A),
  leaveRequestOverviewBackgroundColor: Color(0xff6D76CA),
  totalStaffOverviewBackgroundColor: Color(0xff6dca95),
  totalStudentOverviewBackgroundColor: Color(0xffED7483),
  totalTeacherOverviewBackgroundColor: Color(0xff518EF4),
  sickBackgroundColor: Color(0xff518EF4),
  permissionBackgroundColor: Color(0xffff6e00),
);
