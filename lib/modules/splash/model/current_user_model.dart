class CurrentUserModel {
  bool? status;
  String? message;
  Data? data;

  CurrentUserModel({this.status, this.message, this.data});

  CurrentUserModel.fromJson(Map<String, dynamic> json) {
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

  Data({this.user});

  Data.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class User {
  String? uuid;
  String? fullName;
  String? email;
  String? phoneNumber;
  String? profilePicture;
  bool? isActive;
  String? nidNumber;
  Role? role;
  List<Permissions>? permissions;
  bool? isNotificationEnabled;
  String? deviceTokenForNotification;

  User(
      {this.uuid,
      this.fullName,
      this.email,
      this.phoneNumber,
      this.profilePicture,
      this.isActive,
      this.nidNumber,
      this.role,
      this.permissions,
      this.isNotificationEnabled,
      this.deviceTokenForNotification});

  User.fromJson(Map<String, dynamic> json) {
    uuid = json['uuid'];
    fullName = json['full_name'];
    email = json['email'];
    phoneNumber = json['phone_number'];
    profilePicture = json['profile_picture'];
    isActive = json['is_active'];
    nidNumber = json['nid_number'];
    isNotificationEnabled = json['is_notification_enabled'];
    deviceTokenForNotification = json['device_token_for_notification'];
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
    data['is_active'] = isActive;
    data['nid_number'] = nidNumber;
    data['is_notification_enabled'] = isNotificationEnabled;
    data['device_token_for_notification'] = deviceTokenForNotification;
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
