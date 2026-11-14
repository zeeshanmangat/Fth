import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:family_transit_home/core/constants/colors.dart';
import 'package:family_transit_home/providers/app_state_provider.dart';
import 'package:family_transit_home/shared/widgets/fth_common_widgets.dart';
import 'package:family_transit_home/ui/widgets/accommodation_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  bool _isCheckingAvailability = false;
  bool _hasCheckedDates = false;
  String? _availabilityError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDatesAndSearch(AppStateProvider state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
    );
    if (picked == null) return;

    final nights = picked.end.difference(picked.start).inDays;
    if (nights < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Official FTH policy requires a minimum stay of 2 nights.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _checkIn = picked.start;
      _checkOut = picked.end;
    });
    state.setDateRange(picked);
    await _runLiveAvailabilityCheck(state);
  }

  Future<void> _runLiveAvailabilityCheck(AppStateProvider state) async {
    setState(() {
      _isCheckingAvailability = true;
      _availabilityError = null;
    });
    try {
      await state.searchLiveAvailability(
        checkIn: _checkIn,
        checkOut: _checkOut,
        guests: state.totalGuests,
      );
      if (!mounted) return;
      setState(() => _hasCheckedDates = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _availabilityError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingAvailability = false);
    }
  }

  void _showFilterModal(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final estates = [
      'All Estates',
      ...state.estates.map((e) => e.name),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Filter Accommodations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        state.resetFilters();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Reset All',
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Location / Estate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: estates.map((e) {
                    final isSel = state.selectedEstate == e;
                    return ChoiceChip(
                      label: Text(e),
                      selected: isSel,
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setModalState(() {
                          state.setSelectedEstate(val ? e : 'All Estates');
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Apartment Category Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'All Categories',
                    ...state.allAccommodations
                        .map((a) => a.categoryType)
                        .where((c) => c.trim().isNotEmpty)
                        .toSet(),
                  ].map((catType) {
                    final isSel = state.selectedCategoryType == catType;
                    return ChoiceChip(
                      label: Text(catType),
                      selected: isSel,
                      selectedColor: AppColors.primaryNavy,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setModalState(() {
                          state.setSelectedCategoryType(
                            val ? catType : 'All Categories',
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Bedrooms',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final bedOptions = state.allAccommodations
                        .map((a) => a.bedrooms)
                        .toSet()
                        .toList()
                      ..sort();
                    final beds = bedOptions.isNotEmpty ? bedOptions : [1, 2, 3];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: beds.map((bed) {
                        final isSel = state.selectedBedroomFilter == bed;
                        return ChoiceChip(
                          label: Text(
                            bed == 0
                                ? 'Studio'
                                : '$bed Bedroom${bed > 1 ? 's' : ''}',
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primaryNavy,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              state.setBedroomFilter(val ? bed : null);
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Price Range / Night',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      'K${state.priceRange.start.toInt()} - K${state.priceRange.end.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: state.priceRange,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  activeColor: AppColors.goldAccent,
                  inactiveColor: AppColors.surfaceMuted,
                  onChanged: (vals) {
                    setModalState(() {
                      state.setPriceRange(vals);
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters (${state.accommodations.length} results)',
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const FthAppBarTitle(title: 'Explore Accommodations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => state.setSearchQuery(v),
                  decoration: InputDecoration(
                    hintText: 'Search by estate, bedrooms, amenities...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.goldDark,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              state.setSearchQuery('');
                            },
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.primaryNavy,
                            ),
                            onPressed: () => _showFilterModal(context),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDatesAndSearch(state),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.date_range_rounded,
                                size: 18,
                                color: AppColors.emeraldGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${DateFormat('dd MMM').format(_checkIn)} - ${DateFormat('dd MMM').format(_checkOut)} (${_checkOut.difference(_checkIn).inDays}N)',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isCheckingAvailability
                            ? null
                            : () => _runLiveAvailabilityCheck(state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: _isCheckingAvailability
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Check Live',
                                style: TextStyle(fontSize: 12),
                              ),
                      ),
                    ],
                  ),
                ),
                if (_availabilityError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _availabilityError!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.accommodations.length} Available Unit${state.accommodations.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryNavy,
                  ),
                ),
                if (state.selectedEstate != 'All Estates' ||
                    state.selectedCategoryType != 'All Categories' ||
                    state.selectedBedroomFilter != null)
                  TextButton(
                    onPressed: () => state.resetFilters(),
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(fontSize: 12, color: AppColors.goldDark),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: state.accommodations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apartment_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No accommodations match your filter.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            state.resetFilters();
                          },
                          child: const Text('Reset Search Criteria'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: state.accommodations.length,
                    itemBuilder: (context, index) {
                      final item = state.accommodations[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_hasCheckedDates && (item.availableUnits ?? 1) <= 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Sold Out for Selected Dates',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          AccommodationCard(accommodation: item),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
