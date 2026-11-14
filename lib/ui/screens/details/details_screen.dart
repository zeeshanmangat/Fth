import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:family_transit_home/core/constants/colors.dart';
import 'package:family_transit_home/core/constants/strings.dart';
import 'package:family_transit_home/data/models/accommodation.dart';
import 'package:family_transit_home/providers/app_state_provider.dart';
import 'package:family_transit_home/shared/widgets/fth_common_widgets.dart';
import 'package:family_transit_home/ui/screens/booking/booking_screen.dart';
import 'package:family_transit_home/ui/widgets/amenity_chip.dart';
import 'package:family_transit_home/ui/widgets/custom_button.dart';
import 'package:family_transit_home/ui/widgets/fth_image.dart';
import 'package:family_transit_home/ui/widgets/photo_lightbox_viewer.dart';

class DetailsScreen extends StatefulWidget {
  final Accommodation accommodation;
  const DetailsScreen({super.key, required this.accommodation});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  void _shareListing() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Accommodation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF25D366),
                child: Icon(Icons.chat_rounded, color: Colors.white),
              ),
              title: const Text('Share via WhatsApp'),
              subtitle: Text(widget.accommodation.title),
              onTap: () async {
                Navigator.pop(ctx);
                final text = Uri.encodeComponent(
                  'Check out ${widget.accommodation.title} at Family Transit Home Port Moresby: ${AppStrings.websiteUrl}',
                );
                final uri = Uri.parse('https://wa.me/?text=$text');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryNavy,
                child: Icon(Icons.copy_rounded, color: Colors.white),
              ),
              title: const Text('Copy Details Link'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Accommodation link copied to clipboard.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHouseRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'House Rules & Policies',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 14),
            _policyRow(
              Icons.schedule_rounded,
              'Check-In / Check-Out',
              'Check-in from 1:00 PM (Early check-in free when unit is available) | Check-out by 10:00 AM (Late check-out: PGK 200.00 fee).',
            ),
            _policyRow(
              Icons.directions_car_rounded,
              'Guest Vehicle Pass & Gated Access',
              '24/7 security guard gate. Registered guest vehicles are issued a Guest Vehicle Pass through Kennedy Estate guardhouse & Reception (Unit 16G-02).',
            ),
            _policyRow(
              Icons.policy_rounded,
              'Cancellation, No-Show & Non-Transferable Policy',
              'Cancellation >=48h before check-in: 70% refund (30% fee). Within 48h: 0% refund. No refund for no-show guests and bookings are non-transferable.',
            ),
            _policyRow(
              Icons.smoke_free_rounded,
              'Smoking Policy',
              'Strictly non-smoking inside apartments. Designated outdoor smoking area available.',
            ),
            _policyRow(
              Icons.volume_mute_rounded,
              'Quiet Hours',
              'Quiet hours observed between 10:00 PM and 6:00 AM for residential tranquility.',
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Close',
              variant: ButtonVariant.primary,
              width: double.infinity,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.goldDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isFav = state.isFavorite(widget.accommodation.id);
    final images = widget.accommodation.galleryImages;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.primaryNavyDark,
                expandedHeight: 330,
                pinned: true,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  const Center(child: FthBrandLogoBadge(size: 36)),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _shareListing,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.error : Colors.white,
                        size: 20,
                      ),
                      onPressed: () =>
                          state.toggleFavorite(widget.accommodation.id),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (idx) =>
                            setState(() => _currentImageIndex = idx),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              PhotoLightboxViewer.show(
                                context,
                                images: images,
                                initialIndex: index,
                                title: widget.accommodation.title,
                              );
                            },
                            child: FthImage(
                              imagePath: images[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: InkWell(
                          onTap: () {
                            PhotoLightboxViewer.show(
                              context,
                              images: images,
                              initialIndex: _currentImageIndex,
                              title: widget.accommodation.title,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.fullscreen_rounded,
                                  size: 16,
                                  color: AppColors.goldAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_currentImageIndex + 1}/${images.length} (Tap to Zoom)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.accommodation.estate,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldAccent,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.goldDark,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'FTH Direct Standard',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.accommodation.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.goldDark,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.accommodation.locationArea,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _specColumn(
                              Icons.people_outline_rounded,
                              '${widget.accommodation.maxGuests} Max',
                              'Guests',
                            ),
                            _dividerVertical(),
                            _specColumn(
                              Icons.bed_outlined,
                              '${widget.accommodation.bedrooms}',
                              'Bedrooms',
                            ),
                            _dividerVertical(),
                            _specColumn(
                              Icons.bathtub_outlined,
                              '${widget.accommodation.bathrooms}',
                              'Bathrooms',
                            ),
                            _dividerVertical(),
                            _specColumn(
                              Icons.square_foot_rounded,
                              '${widget.accommodation.sizeSqm.toInt()} m²',
                              'Area',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hotel_rounded,
                              size: 20,
                              color: AppColors.primaryNavy,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.accommodation.bedConfiguration,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'About This Accommodation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.accommodation.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Amenities & Inclusions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          Text(
                            '${widget.accommodation.amenities.length} Total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.accommodation.amenities.map((amenity) {
                          return AmenityChip(amenity: amenity);
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  color: AppColors.goldDark,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Neighborhood & Transit Distances',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _distanceRow(
                              Icons.flight_takeoff_rounded,
                              'Jacksons International Airport',
                              '5 minutes (Free Shuttle Included)',
                            ),
                            _distanceRow(
                              Icons.shopping_bag_outlined,
                              'Vision City Mega Mall',
                              '8 minutes drive',
                            ),
                            _distanceRow(
                              Icons.storefront_outlined,
                              'Rangeview Shopping Plaza',
                              '10 minutes drive',
                            ),
                            _distanceRow(
                              Icons.local_hospital_outlined,
                              'Pacific International Hospital (PIH)',
                              '12 minutes drive',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showHouseRules,
                        icon: const Icon(Icons.policy_rounded, size: 18),
                        label: const Text(
                          'View House Rules & Cancellation Policy',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryNavy,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          minimumSize: const Size(double.infinity, 46),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: const Border(
                  top: BorderSide(color: AppColors.borderSubtle),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${AppStrings.currencySymbol}${widget.accommodation.pricePerNight % 1 == 0 ? widget.accommodation.pricePerNight.toInt() : widget.accommodation.pricePerNight.toStringAsFixed(2)} ',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              const TextSpan(
                                text: AppStrings.perNight,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomButton(
                        text: 'Book Stay Now',
                        variant: ButtonVariant.gold,
                        icon: Icons.calendar_month_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(
                                accommodation: widget.accommodation,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.goldDark),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _dividerVertical() {
    return Container(width: 1, height: 32, color: AppColors.borderSubtle);
  }

  Widget _distanceRow(IconData icon, String name, String dist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            dist,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.goldDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
