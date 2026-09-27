import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/equipment.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/equipment_icon.dart';
import '../../widgets/pressable.dart';
import '../equipment/equipment_details_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

/// Sort options for the equipment grid.
enum _EquipmentSort {
  name('Name'),
  availability('Availability'),
  stock('Stock');

  final String label;
  const _EquipmentSort(this.label);
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  String? _availabilityFilter;
  EquipmentCondition? _conditionFilter;
  _EquipmentSort _sort = _EquipmentSort.name;

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

  /// Applies the selected sort to an already-filtered list.
  List<Equipment> _applySort(List<Equipment> items) {
    final sorted = [...items];
    switch (_sort) {
      case _EquipmentSort.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _EquipmentSort.availability:
        // Availability rank first, then most free units within a rank.
        int rank(Equipment e) => switch (e.availabilityStatus) {
              'Available' => 0,
              'Limited' => 1,
              _ => 2,
            };
        sorted.sort((a, b) {
          final byRank = rank(a).compareTo(rank(b));
          if (byRank != 0) return byRank;
          return b.availableQuantity.compareTo(a.availableQuantity);
        });
      case _EquipmentSort.stock:
        sorted.sort((a, b) => b.availableQuantity.compareTo(a.availableQuantity));
    }
    return sorted;
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Sort by', style: Theme.of(ctx).textTheme.titleLarge),
              ),
              ..._EquipmentSort.values.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    switch (s) {
                      _EquipmentSort.name => Icons.sort_by_alpha_rounded,
                      _EquipmentSort.availability => Icons.event_available_rounded,
                      _EquipmentSort.stock => Icons.inventory_2_outlined,
                    },
                    size: 21,
                    color: _sort == s ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    s.label,
                    style: TextStyle(
                      fontWeight: _sort == s ? FontWeight.w700 : FontWeight.w500,
                      color: _sort == s ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: _sort == s
                      ? const Icon(Icons.check_rounded,
                          size: 20, color: AppColors.primary)
                      : null,
                  onTap: () => setState(() => _sort = s),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openFilterSheet(List<String> categories) {
    String? category = _categoryFilter;
    String? availability = _availabilityFilter;
    EquipmentCondition? condition = _conditionFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters', style: Theme.of(ctx).textTheme.titleLarge),
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
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category', style: Theme.of(ctx).textTheme.titleSmall),
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
                          Text('Availability', style: Theme.of(ctx).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Available', 'Limited', 'Unavailable'].map((a) {
                              return FilterChip(
                                label: Text(a),
                                selected: availability == a,
                                onSelected: (sel) =>
                                    setSheetState(() => availability = sel ? a : null),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text('Condition', style: Theme.of(ctx).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: EquipmentCondition.values.map((c) {
                              return FilterChip(
                                label: Text(c.label),
                                selected: condition == c,
                                onSelected: (sel) =>
                                    setSheetState(() => condition = sel ? c : null),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
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
                      child: const Text('Apply'),
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
    final filtered = _applySort(_applyFilters(appState.equipment));
    final categories = appState.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Equipment',
                            style: Theme.of(context).textTheme.headlineLarge),
                      ),
                      _HeaderPillButton(
                        icon: Icons.sort_rounded,
                        active: _sort != _EquipmentSort.name,
                        onTap: _openSortSheet,
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        active: _hasActiveFilters,
                        onTap: () => _openFilterSheet(categories),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filtered.length} of ${appState.equipment.length}  ·  ${_sort.label}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),

                  // ── Search ──────────────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search_rounded, size: 21),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 19),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _query = '';
                              }),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Category chips ──────────────────────────────────────
                  if (categories.isNotEmpty)
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        children: [
                          _CategoryChip(
                            label: 'All',
                            selected: _categoryFilter == null,
                            onTap: () => setState(() => _categoryFilter = null),
                          ),
                          ...categories.map(
                            (c) => _CategoryChip(
                              label: c,
                              selected: _categoryFilter == c,
                              onTap: () =>
                                  setState(() => _categoryFilter = c),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Active filter chips (availability / condition) ───────
                  if (_availabilityFilter != null || _conditionFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_availabilityFilter != null)
                            _RemovableChip(
                              label: _availabilityFilter!,
                              onRemove: () =>
                                  setState(() => _availabilityFilter = null),
                            ),
                          if (_conditionFilter != null)
                            _RemovableChip(
                              label: _conditionFilter!.label,
                              onRemove: () =>
                                  setState(() => _conditionFilter = null),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Grid ──────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No equipment found',
                      subtitle: 'Try adjusting your search or filters.',
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return _EquipmentTile(
                          equipment: e,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    EquipmentDetailsScreen(equipmentId: e.id)),
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

// ---------------------------------------------------------------------------
// Grid tile — icon, name, category, availability dot + stock count.
// ---------------------------------------------------------------------------
class _EquipmentTile extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const _EquipmentTile({required this.equipment, required this.onTap});

  Color get _availabilityColor => switch (equipment.availabilityStatus) {
        'Available' => AppColors.success,
        'Limited' => AppColors.warning,
        _ => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    equipmentIcon('${equipment.category} ${equipment.name}'),
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _availabilityColor, shape: BoxShape.circle),
                ),
              ],
            ),
            const Spacer(),
            Text(
              equipment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(
              equipment.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${equipment.availableQuantity}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _availabilityColor,
                  ),
                ),
                Text(
                  ' / ${equipment.totalQuantity} available',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip — quiet pill that fills with brand color when selected.
// ---------------------------------------------------------------------------
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Removable chip for active availability/condition filters.
// ---------------------------------------------------------------------------
class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort button — same flat square style as the filter toggle.
class _HeaderPillButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _HeaderPillButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider.withValues(alpha: 0.6),
            ),
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.textPrimary,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider.withValues(alpha: 0.6),
            ),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: active ? Colors.white : AppColors.textPrimary,
            size: 21,
          ),
        ),
      ),
    );
  }
}
