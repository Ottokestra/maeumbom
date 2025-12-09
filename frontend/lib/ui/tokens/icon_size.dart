import 'package:flutter/material.dart';

/// Icon Size Tokens
/// 디자인 시스템에서 사용하는 표준 아이콘 사이즈 정의
class AppIconSizes {
  AppIconSizes._(); // 인스턴스화 방지

  static const double xs = 16; // 16x16
  static const double sm = 32; // 32x32
  static const double md = 48; // 48x48 (기본)
  static const double lg = 64; // 64x64
  static const double xl = 80; // 80x80
  static const double xxl = 96; // 96x96

  static const Size xsSize = Size(xs, xs);
  static const Size smSize = Size(sm, sm);
  static const Size mdSize = Size(md, md);
  static const Size lgSize = Size(lg, lg);
  static const Size xlSize = Size(xl, xl);
  static const Size xxlSize = Size(xxl, xxl);
}
