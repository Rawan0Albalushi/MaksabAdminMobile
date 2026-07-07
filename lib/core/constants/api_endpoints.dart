/// REST paths relative to [AppConfig.apiUrl].
abstract class ApiEndpoints {
  ApiEndpoints._();

  static const authLogin = 'auth/login';
  static const authLogout = 'auth/logout';

  static const adminOrdersPaginate = 'dashboard/admin/orders/paginate';
  static String adminOrder(int id) => 'dashboard/admin/orders/$id';
  static String adminOrderStatus(int id) => 'dashboard/admin/order/$id/status';
  static String adminShop(String id) => 'dashboard/admin/shops/$id';

  static const adminZones = 'dashboard/admin/zones';

  static const adminStatistics = 'dashboard/admin/statistics';
  static const adminOrdersOverview =
      'dashboard/admin/statistics/orders/overview';
  static const adminOrdersChart = 'dashboard/admin/statistics/orders/chart';

  static const adminRefundsPaginate = 'dashboard/admin/order-refunds/paginate';
  static String adminRefund(int id) => 'dashboard/admin/order-refunds/$id';
}
