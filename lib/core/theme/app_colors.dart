import 'package:flutter/material.dart';

/// Maksab brand palette — teal → orange gradient identity.
abstract class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00979B);
  static const Color primaryDark = Color(0xFF007A7D);
  static const Color accent = Color(0xFFFF3D00);

  static const Color background = Color(0xFFF4F4F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF4F5F8);

  static const Color textPrimary = Color(0xFF232B2F);
  static const Color textSecondary = Color(0xFF898989);
  static const Color textHint = Color(0xFFA7A7A7);

  static const Color border = Color(0xFFE6E6E6);
  static const Color divider = Color(0xFFEDEDED);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFFA826);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF00979B);

  static const Color statusNew = Color(0xFF00979B);
  static const Color statusAccepted = Color(0xFF007A7D);
  static const Color statusCooking = Color(0xFFFF3D00);
  static const Color statusReady = Color(0xFF7B1FA2);
  static const Color statusOnWay = Color(0xFF1565C0);
  static const Color statusDelivered = Color(0xFF2E7D32);
  static const Color statusCanceled = Color(0xFFD32F2F);

  static const Color refundPending = Color(0xFFFFA826);
  static const Color refundAccepted = Color(0xFF00979B);
  static const Color refundCanceled = Color(0xFFD32F2F);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00979B), Color(0xFFFF3D00)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00979B), Color(0xFFFF3D00)],
  );
}
