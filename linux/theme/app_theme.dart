import 'package:flutter/material.dart';

class AppColors {
  static const bg        = Color(0xFFF1F5F9);  // light gray bg
  static const surface   = Color(0xFFFFFFFF);  // white cards
  static const surface2  = Color(0xFFF8FAFC);  // slightly off-white
  static const border    = Color(0xFFE2E8F0);  // light border
  static const border2   = Color(0xFFCBD5E1);  // medium border
  static const blue      = Color(0xFF2563EB);  // deeper blue for contrast
  static const purple    = Color(0xFF7C3AED);
  static const blueDim   = Color(0xFFDBEAFE);  // light blue bg
  static const green     = Color(0xFF059669);  // deeper green
  static const greenDim  = Color(0xFFD1FAE5);  // light green bg
  static const amber     = Color(0xFFD97706);  // deeper amber
  static const amberDim  = Color(0xFFFEF3C7);  // light amber bg
  static const red       = Color(0xFFDC2626);
  static const violet    = Color(0xFF7C3AED);
  static const cyan      = Color(0xFF0891B2);
  static const slate     = Color(0xFF64748B);
  static const text      = Color(0xFF1E293B);  // dark text
  static const textDim   = Color(0xFF64748B);  // medium gray text
  static const textMuted = Color(0xFF94A3B8);  // light gray text
}

class AppTextStyles {
  static const fontFamily = 'DM Sans';
  static const monoFamily = 'JetBrainsMono';

  static const topBarTitle = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text);
  static const sectionLabel = TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6);
  static const fieldLabel = TextStyle(fontFamily: fontFamily, fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDim);
  static const nodeName = TextStyle(fontFamily: fontFamily, fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.text);
  static const nodeSubtitle = TextStyle(fontFamily: fontFamily, fontSize: 10, color: AppColors.textDim);
  static const statLabel = TextStyle(fontFamily: fontFamily, fontSize: 10.5, color: AppColors.textDim);
  static const statValue = TextStyle(fontFamily: monoFamily, fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.text);
  static const badge = TextStyle(fontFamily: fontFamily, fontSize: 9.5, fontWeight: FontWeight.w700);
  static const tableHeader = TextStyle(fontFamily: monoFamily, fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.green);
  static const tableCell = TextStyle(fontFamily: monoFamily, fontSize: 9, color: AppColors.text);
}
