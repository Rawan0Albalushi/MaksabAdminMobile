/// API date strings must always use Western digits (Y-m-d), regardless of app locale.
abstract class ApiDate {
  ApiDate._();

  static String format(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
