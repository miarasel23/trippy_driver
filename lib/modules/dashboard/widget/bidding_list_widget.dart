import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/create_rental_trip_model.dart';
import '../../../../utils/app_urls.dart';
import '../../../../widgets/radar_animation.dart';
import '../../../../widgets/full_screen_image_gallery.dart';
import '../../../../main.dart';

class BiddingListWidget extends StatelessWidget {
  final bool isDark;
  final RentalTrip currentTrip;
  final Function(RentalDriverBid bid) onAcceptBid;

  const BiddingListWidget({
    super.key,
    required this.isDark,
    required this.currentTrip,
    required this.onAcceptBid,
  });

  void _showReviewsBottomSheet(BuildContext context, RentalDriverBid bid, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E26) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Driver Reviews",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bid.ratingList!.length,
                  itemBuilder: (context, index) {
                    final review = bid.ratingList![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252833) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: review.customerPhoto != null 
                                  ? NetworkImage("${AppUrls.imageBaseUrl}${review.customerPhoto}")
                                  : null,
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                child: review.customerPhoto == null
                                  ? Icon(Icons.person, size: 16, color: isDark ? Colors.white54 : Colors.black54)
                                  : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.customerName ?? "Customer",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      review.createdAt?.split('T').first ?? "",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  int rating = review.rating ?? 0;
                                  return Icon(
                                    starIndex < rating ? Icons.star : Icons.star_border,
                                    size: 14,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (review.comments != null && review.comments!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              review.comments!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        const SizedBox(
           height: 50,
           child: RadarAnimation(size: 50, color: Color(0xFF6C63FF)),
        ),
        const SizedBox(height: 4),
        Text(
          "Searching for more drivers...",
          style: GoogleFonts.poppins(
             fontSize: 12,
             color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Drivers Found! (${currentTrip.totalBids ?? currentTrip.drivers.length})",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: currentTrip.drivers.length,
            itemBuilder: (context, index) {
              final bid = currentTrip.drivers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1E26) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: bid.profilePicture != null 
                            ? NetworkImage("${AppUrls.imageBaseUrl}${bid.profilePicture}") 
                            : null,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                          child: bid.profilePicture == null 
                            ? Icon(Icons.person, color: isDark ? Colors.white : Colors.black54) 
                            : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (bid.name ?? "Driver").toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(AppLocalizations.of(context).translate("total") ?? "Total").toUpperCase()}: ' + 
                                (AppLocalizations.of(context).locale.languageCode == 'bn' 
                                    ? '৳${bid.totalAmount ?? bid.bidAmount ?? '0.00'}' 
                                    : 'BDT ${bid.totalAmount ?? bid.bidAmount ?? '0.00'}'),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (bid.ratingList != null && bid.ratingList!.isNotEmpty) {
                                  _showReviewsBottomSheet(context, bid, isDark);
                                } else {
                                  globalScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                                  globalScaffoldMessengerKey.currentState?.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context).translate("no_reviews") ?? "No reviews available yet.",
                                        style: TextStyle(color: isDark ? Colors.black : Colors.white),
                                      ),
                                      backgroundColor: isDark ? Colors.white : Colors.black,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${bid.averageRating?.toStringAsFixed(1) ?? "0.0"} (${bid.totalCompletedTrips ?? 0} trips)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: (bid.ratingList != null && bid.ratingList!.isNotEmpty) 
                                          ? Colors.blueAccent 
                                          : (isDark ? Colors.white54 : Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => onAcceptBid(bid),
                              child: Text("Accept", style: GoogleFonts.poppins(color: isDark ? Colors.black : Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (bid.carPhotos != null && bid.carPhotos!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: bid.carPhotos!.length,
                          itemBuilder: (context, photoIndex) {
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => FullScreenImageGallery(
                                    images: bid.carPhotos!,
                                    initialIndex: photoIndex,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage("${AppUrls.imageBaseUrl}${bid.carPhotos![photoIndex]}"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
