class OtpReceiveModel {
  bool? status;
  String? message;
  Data? data;

  OtpReceiveModel({this.status, this.message, this.data});

  OtpReceiveModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  User? user;
  String? accessToken;
  String? tokenType;

  Data({this.user, this.accessToken, this.tokenType});

  Data.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    accessToken = json['access_token'];
    tokenType = json['token_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    return data;
  }
}

class User {
  String? uuid;
  String? fullName;
  String? email;
  String? phoneNumber;
  String? profilePicture;
  String? countryCode;
  String? isActive;  // API returns "ACTIVE" / "INACTIVE" string
  Role? role;
  List<Permissions>? permissions;

  User(
      {this.uuid,
      this.fullName,
      this.email,
      this.phoneNumber,
      this.profilePicture,
      this.isActive,
      this.role,
      this.permissions});

  User.fromJson(Map<String, dynamic> json) {
    uuid = json['uuid'];
    fullName = json['full_name'];
    email = json['email'];
    phoneNumber = json['phone_number'];
    profilePicture = json['profile_picture'];
    countryCode = json['country_code'];
    isActive = json['is_active']?.toString();
    role = json['role'] != null ? Role.fromJson(json['role']) : null;
    if (json['permissions'] != null) {
      permissions = <Permissions>[];
      json['permissions'].forEach((v) {
        permissions!.add(Permissions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['uuid'] = uuid;
    data['full_name'] = fullName;
    data['email'] = email;
    data['phone_number'] = phoneNumber;
    data['profile_picture'] = profilePicture;
    data['country_code'] = countryCode;
    data['is_active'] = isActive;
    if (role != null) {
      data['role'] = role!.toJson();
    }
    if (permissions != null) {
      data['permissions'] = permissions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Role {
  String? uuid;
  String? name;
  String? description;

  Role({this.uuid, this.name, this.description});

  Role.fromJson(Map<String, dynamic> json) {
    uuid = json['uuid'];
    name = json['name'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['uuid'] = uuid;
    data['name'] = name;
    data['description'] = description;
    return data;
  }
}

class Permissions {
  String? uuid;
  String? name;
  String? code;

  Permissions({this.uuid, this.name, this.code});

  Permissions.fromJson(Map<String, dynamic> json) {
    uuid = json['uuid'];
    name = json['name'];
    code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['uuid'] = uuid;
    data['name'] = name;
    data['code'] = code;
    return data;
  }
}
