class AppUser {
  final String? id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profilePhoto;

  // Geriye dönük uyumluluk getter'ları
  // ignore: non_constant_identifier_names
  String? get first_name => firstName;
  // ignore: non_constant_identifier_names
  String? get last_name => lastName;
  // ignore: non_constant_identifier_names
  String? get profile_photo => profilePhoto;

  AppUser({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.profilePhoto,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'],
    email: json['email'],
    firstName: json['first_name'] ?? json['firstName'],
    lastName: json['last_name'] ?? json['lastName'],
    profilePhoto: json['profile_photo'] ?? json['profilePhoto'],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "firstName": firstName,
    "lastName": lastName,
    "profilePhoto": profilePhoto,
  };
}
