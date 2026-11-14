import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:family_transit_home/core/constants/colors.dart';
import 'package:family_transit_home/providers/app_state_provider.dart';
import 'package:family_transit_home/shared/widgets/fth_common_widgets.dart';
import 'package:family_transit_home/ui/widgets/accommodation_card.dart';

class ListingScreen extends StatelessWidget {
  final String title;
  const ListingScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: FthAppBarTitle(title: title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.accommodations.length,
        itemBuilder: (context, index) {
          final item = state.accommodations[index];
          return AccommodationCard(accommodation: item);
        },
      ),
    );
  }
}
