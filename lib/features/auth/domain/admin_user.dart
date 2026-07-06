import '../../../core/config/app_config.dart';
import '../../../core/utils/media_url.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.roles,
    this.img,
    this.token,
  });

  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final List<String> roles;
  final String? img;
  final String? token;

  String get fullName => '$firstname $lastname'.trim();

  bool get isAdminPortal {
    if (roles.length == 1 && roles.first == 'user') return false;
    return roles.any(AppConfig.adminRoles.contains);
  }

  factory AdminUser.fromJson(Map<String, dynamic> json, {String? token}) {
    final roles = (json['roles'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['role'] != null ? [json['role'].toString()] : <String>[]);

    return AdminUser(
      id: json['id'] as int,
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: roles,
      img: MediaUrl.resolve(json['img']?.toString()),
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'roles': roles,
        'img': img,
      };
}
