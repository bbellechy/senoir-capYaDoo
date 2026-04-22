class User {
  final String id;
  final String username;
  final String fullName;
  final String phoneNumber;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String sanitize(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.toLowerCase() == 'null') return '';
      return text;
    }

    final resolvedFullName = sanitize(json['fullName']).isNotEmpty
        ? sanitize(json['fullName'])
        : sanitize(json['name']).isNotEmpty
        ? sanitize(json['name'])
        : '${sanitize(json['firstName'])} ${sanitize(json['lastName'])}'.trim();

    return User(
      id: sanitize(json['id']),
      username: sanitize(json['username']),
      fullName: resolvedFullName,
      phoneNumber: sanitize(json['phoneNumber']).isNotEmpty
          ? sanitize(json['phoneNumber'])
          : sanitize(json['phone']).isNotEmpty
          ? sanitize(json['phone'])
          : sanitize(json['phone_number']).isNotEmpty
          ? sanitize(json['phone_number'])
          : sanitize(json['mobile']).isNotEmpty
          ? sanitize(json['mobile'])
          : sanitize(json['mobileNumber']).isNotEmpty
          ? sanitize(json['mobileNumber'])
          : sanitize(json['tel']).isNotEmpty
          ? sanitize(json['tel'])
          : sanitize(json['telephone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };
  }
}
