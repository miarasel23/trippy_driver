import '../store/user_data_store.dart';

class AppUrls {
  static const String googleApiKey = 'AIzaSyAYf-MPMgwHhXT2h-kKSchXFH5GiwuURcw';
  static const String baseUrl = "http://3.209.161.158/api";
  static const String imageBaseUrl ="$baseUrl/assets/uploads/images/";
  // customer
  static const String sendOtpCustomer =
      "$baseUrl/v1/customer/send-otp-for-signup-or-login";
  static const String verifyOtpCustomer =
      "$baseUrl/v1/customer/otp-verification-with-login";
  static const String getCurrentCustomerUser =
      "$baseUrl/v1/customer/get-current-customer-user";
  static const String customerProfileUpdate =
      "$baseUrl/v1/customer/profile-update";
  static const String customerProfilePictureUpdate =
      "$baseUrl/v1/customer/customer-profile-picture-update";
  static const String rentalInfo = "$baseUrl/v1/rental-trip/rental-info";
  static const String searchLocation = "$baseUrl/v1/global-api/search-location";
  static const String getCustomerLocations = "$baseUrl/v1/customer/get-locations";
  static const String tripPriceDetailsCustomer = "$baseUrl/v1/rental-trip/trip-price-details-customer";

  // Rental Trip - Booking
  static const String createRentalTrip = "$baseUrl/v1/rental-trip/create-rental-trip";
  static const String rentalBidTripListForCustomer = "$baseUrl/v1/rental-trip/rental-bid-trip-list_for_customer";
  static const String acceptTripForCustomer = "$baseUrl/v1/rental-trip/accept_trip_for_customer";
  static const String cancelTripDriverOrCustomerAdmin = "$baseUrl/v1/rental-trip/cancel-trip-driver-or-customer-admin";
  static const String rentalTripGiveReview = "$baseUrl/v1/rental-trip/give-review";

  static const String saveCustomerLocation = "$baseUrl/v1/customer/save-location";
  static const String deleteCustomerLocation = "$baseUrl/v1/customer/delete-location";
  static const String saveCustomerDriverTrack = "$baseUrl/v1/customer-driver-track/create";
  static const String customerDriverTrackGet = "$baseUrl/v1/customer-driver-track/get";

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
