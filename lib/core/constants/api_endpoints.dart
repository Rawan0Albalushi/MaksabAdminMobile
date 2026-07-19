/// REST paths relative to [AppConfig.apiUrl].
abstract class ApiEndpoints {
  ApiEndpoints._();

  static const authLogin = 'auth/login';
  static const authLogout = 'auth/logout';

  static const adminOrdersPaginate = 'dashboard/admin/orders/paginate';
  static String adminOrder(int id) => 'dashboard/admin/orders/$id';
  static String adminOrderStatus(int id) => 'dashboard/admin/order/$id/status';
  static String adminOrderDeliveryman(int id) =>
      'dashboard/admin/order/$id/deliveryman';
  static String adminShop(String id) => 'dashboard/admin/shops/$id';
  static const adminShopsPaginate = 'dashboard/admin/shops/paginate';
  static String adminShopVerify(String uuid) =>
      'dashboard/admin/shops/$uuid/verify';
  static String adminShopStatusChange(String uuid) =>
      'dashboard/admin/shops/$uuid/status/change';
  static String adminShopWorkingStatus(String uuid) =>
      'dashboard/admin/shops/working/status/$uuid';

  static const adminZones = 'dashboard/admin/zones';
  static String adminManagerZones(String uuid) =>
      'dashboard/admin/zones/manager/$uuid';
  static String adminUserZones(String uuid) =>
      'dashboard/admin/zones/user/$uuid';
  static const adminAssignDriverZones = 'dashboard/admin/zones/assign-driver';

  static const adminDeliverymansPaginate =
      'dashboard/admin/deliverymans/paginate';
  static String adminUser(String uuid) => 'dashboard/admin/users/$uuid';
  static String adminUserActive(String uuid) =>
      'dashboard/admin/users/$uuid/active';

  /// Deliveryman settings requests (`/deliveryman/request` in portal).
  static const adminRequestModels = 'dashboard/admin/request-models';
  static String adminRequestModelStatus(int id) =>
      'dashboard/admin/request-model/status/$id';

  static const adminStatistics = 'dashboard/admin/statistics';
  static const adminOrdersOverview =
      'dashboard/admin/statistics/orders/overview';
  static const adminOrdersChart = 'dashboard/admin/statistics/orders/chart';

  static const adminRefundsPaginate = 'dashboard/admin/order-refunds/paginate';
  static String adminRefund(int id) => 'dashboard/admin/order-refunds/$id';
}
