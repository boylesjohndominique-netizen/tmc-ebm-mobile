import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/equipment.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/equipment_card.dart';
import 'equipment_details_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  String? _availabilityFilter;
  EquipmentCondition? _conditionFilter;

  bool get _hasActiveFilters =>
      _categoryFilter != null || _availabilityFilter != null || _conditionFilter != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Equipment> _applyFilters(List<Equipment> all) {
    return all.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.name.toLowerCase().contains(_query.toLowerCase()) ||
          e.category.toLowerCase().contains(_query.toLowerCase()) ||
          e.description.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory = _categoryFilter == null || e.category == _categoryFilter;
      final matchesAvailability =
          _availabilityFilter == null || e.availabilityStatus == _availabilityFilter;
      final matchesCondition = _conditionFilter == null || e.condition == _conditionFilter;
      return matchesQuery && matchesCategory && matchesAvailability && matchesCondition;
    }).toList();
  }

  void _openFilterSheet(List<String> categories) {
    String? category = _categoryFilter;
    String? availability = _availabilityFilter;
    EquipmentCondition? condition = _conditionFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Equipment', style: Theme.of(ctx).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          category = null;
                          availability = null;
                          condition = null;
                        }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Category', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((c) {
                      return FilterChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (sel) => setSheetState(() => category = sel ? c : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Availability', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Available', 'Limited', 'Unavailable'].map((a) {
                      return FilterChip(
                        label: Text(a),
                        selected: availability == a,
                        onSelected: (sel) => setSheetState(() => availability = sel ? a : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Condition', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: EquipmentCondition.values.map((c) {
                      return FilterChip(
                        label: Text(c.label),
                        selected: condition == c,
                        onSelected: (sel) => setSheetState(() => condition = sel ? c : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _categoryFilter = category;
                          _availabilityFilter = availability;
                          _conditionFilter = condition;
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final filtered = _applyFilters(appState.equipment);

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search equipment...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _query = '';
                              }),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _hasActiveFilters ? AppColors.primaryBlue : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _hasActiveFilters ? AppColors.primaryBlue : AppColors.divider),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.tune_rounded,
                            color: _hasActiveFilters ? Colors.white : AppColors.textPrimary),
                        onPressed: () => _openFilterSheet(appState.categories),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No equipment found.',
                        subtitle: 'No equipment matches your search.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return EquipmentCard(
                          equipment: e,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EquipmentDetailsScreen(equipmentId: e.id)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
