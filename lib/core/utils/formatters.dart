import 'package:easy_localization/easy_localization.dart';

abstract class Formatters {
  Formatters._();

  /// Dates, times, and numbers always use English regardless of UI language.
  static const displayLocale = 'en';

  static String number(num? value, {String pattern = '#,##0'}) {
    if (value == null) return '—';
    return NumberFormat(pattern, displayLocale).format(value);
  }

  static String orderId(int? id) {
    if (id == null) return '—';
    return id.toString();
  }

  static String currency(num? value) {
    if (value == null) return '—';
    return '${NumberFormat('#,##0.000', displayLocale).format(value)} ${'currency_omr'.tr()}';
  }

  static String date(DateTime date, {String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern, displayLocale).format(date);
  }

  static String time(DateTime date, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern, displayLocale).format(date);
  }

  static String dateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw.replaceAll('Z', ''));
      return DateFormat('dd MMM yyyy • HH:mm', displayLocale).format(dt);
    } catch (_) {
      return raw;
    }
  }

  static String orderStatusLabel(String? status) {
    if (status == null) return '—';
    return switch (status) {
      'new' => 'new_orders'.tr(),
      'accepted' => 'accepted'.tr(),
      'cooking' => 'cooking'.tr(),
      'ready' => 'ready'.tr(),
      'on_a_way' => 'on_the_way'.tr(),
      'delivered' => 'delivered'.tr(),
      'canceled' => 'canceled'.tr(),
      _ => status,
    };
  }

  static String deliveryTypeLabel(String? type) {
    if (type == null || type.isEmpty) return '—';
    return switch (type) {
      'pickup' => 'pickup'.tr(),
      'delivery' => 'delivery'.tr(),
      'dine_in' => 'dine_in'.tr(),
      'point' => 'point'.tr(),
      'kiosk' => 'kiosk'.tr(),
      'shipping' => 'shipping'.tr(),
      _ => type,
    };
  }

  static String refundStatusLabel(String? status) {
    if (status == null) return '—';
    return switch (status) {
      'pending' => 'refund_pending'.tr(),
      'accepted' => 'refund_accepted'.tr(),
      'canceled' => 'refund_rejected'.tr(),
      _ => status,
    };
  }

  static String shopStatusLabel(String? status) {
    if (status == null) return '—';
    return switch (status) {
      'new' => 'shop_status_new'.tr(),
      'approved' => 'shop_status_approved'.tr(),
      'rejected' => 'shop_status_rejected'.tr(),
      'edited' => 'shop_status_edited'.tr(),
      'inactive' => 'shop_status_inactive'.tr(),
      _ => status,
    };
  }

  static String shopFilterLabel(String filter) {
    return switch (filter) {
      'all' => 'all'.tr(),
      'deleted' => 'shop_deleted'.tr(),
      _ => shopStatusLabel(filter),
    };
  }

  static String scheduledDelivery(String? date, String? time) {
    if (date == null || date.isEmpty) return '—';
    if (time == null || time.isEmpty) return date;
    return '$date • $time';
  }
}
