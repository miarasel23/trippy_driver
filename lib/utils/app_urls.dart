import '../store/user_data_store.dart';

class AppUrls {
  static const String googleApiKey = 'AIzaSyAYf-MPMgwHhXT2h-kKSchXFH5GiwuURcw';
  static const String baseUrl = "http://3.209.161.158/api";
  static const String imageBaseUrl ="$baseUrl/assets/uploads/images/";
  // customer
  static const String sendOtpCustomer =
      "$baseUrl/v1/driver/send-otp-for-signup-or-login";
  static const String verifyOtpCustomer =
      "$baseUrl/v1/driver/otp-verification-with-login";
  static const String getCurrentDriverUser =
      "$baseUrl/v1/driver/get-current-driver-user";
  static const String currentRideStatus =
      "$baseUrl/v1/driver/current-ride-status";
  static const String driverProfileUpdate =
      "$baseUrl/v1/driver/profile-update";
  static const String driverProfilePictureUpdate =
      "$baseUrl/v1/driver/driver-profile-picture-update";
  static const String rentalInfo = "$baseUrl/v1/rental-trip/rental-info";
  static const String rentalTripList = "$baseUrl/v1/rental-trip/rental-trip-list";
  static const String searchLocation = "$baseUrl/v1/global-api/search-location";
  static const String getCustomerLocations = "$baseUrl/v1/customer/get-locations";
  static const String createTripBid = "$baseUrl/v1/rental-trip/create-trip-bid";
  static const String rentalBidTripList = "$baseUrl/v1/rental-trip/rental-bid-trip-list";
  static const String createDriverTrack = "$baseUrl/v1/customer-driver-track/create";


  static String? get profileImageUrl {
    final image = UserDataStore.userData?.data?.user?.profilePicture;

    if (image == null || image.isEmpty) {
      return null;
    }

    return "$baseUrl/assets/uploads/images/$image";
  }

  static String? getImageUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return null;
    }

    return "$baseUrl/assets/uploads/images/$avatar";
  }
}
