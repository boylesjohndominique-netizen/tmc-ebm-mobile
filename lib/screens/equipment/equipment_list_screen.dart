import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/equipment.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/equipment_icon.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../equipment/equipment_details_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const EquipmentListScreen({super.key, this.onBack});

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
      _categoryFilter != null ||
      _availabilityFilter != null ||
      _conditionFilter != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Equipment> _applyFilters(List<Equipment> all) {
    final q = _query.trim().toLowerCase();
    return all.where((e) {
      final matchesQuery = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q);
      final matchesCategory =
          _categoryFilter == null || e.category == _categoryFilter;
      final matchesAvailability = _availabilityFilter == null ||
          e.availabilityStatus == _availabilityFilter;
      final matchesCondition =
          _conditionFilter == null || e.condition == _conditionFilter;
      return matchesQuery &&
          matchesCategory &&
          matchesAvailability &&
          matchesCondition;
    }).toList();
  }

  /// Applies the selected sort to an already-filtered list.
  List<Equipment> _applySort(List<Equipment> items) {
    final sorted = [...items];
    switch (_sort) {
      case _EquipmentSort.name:
        sorted.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
        sorted
            .sort((a, b) => b.availableQuantity.compareTo(a.availableQuantity));
    }
    return sorted;
  }

  void _openSortSheet() {
    showGlassSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlassSheetHandle(),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 10, bottom: 8),
              child: Text('Sort by', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            ..._EquipmentSort.values.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (s) {
                    _EquipmentSort.name => Icons.sort_by_alpha_rounded,
                    _EquipmentSort.availability =>
                      Icons.event_available_rounded,
                    _EquipmentSort.stock => Icons.inventory_2_outlined,
                  },
                  size: 21,
                  color:
                      _sort == s ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(
                  s.label,
                  style: TextStyle(
                    fontWeight: _sort == s ? FontWeight.w700 : FontWeight.w500,
                    color:
                        _sort == s ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: _sort == s
                    ? const Icon(Icons.check_circle_rounded,
                        size: 21, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _sort = s);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(List<String> categories) {
    String? category = _categoryFilter;
    String? availability = _availabilityFilter;
    EquipmentCondition? condition = _conditionFilter;

    showGlassSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GlassSheetHandle(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('Filters',
                            style: Theme.of(ctx).textTheme.titleLarge),
                      ),
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
                          Text('Category',
                              style: Theme.of(ctx).textTheme.titleSmall),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((c) {
                              return GlassChip(
                                label: c,
                                selected: category == c,
                                onTap: () => setSheetState(
                                    () => category = category == c ? null : c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                          Text('Availability',
                              style: Theme.of(ctx).textTheme.titleSmall),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Available', 'Limited', 'Unavailable']
                                .map((a) {
                              return GlassChip(
                                label: a,
                                selected: availability == a,
                                onTap: () => setSheetState(() => availability =
                                    availability == a ? null : a),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                          Text('Condition',
                              style: Theme.of(ctx).textTheme.titleSmall),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: EquipmentCondition.values.map((c) {
                              return GlassChip(
                                label: c.label,
                                selected: condition == c,
                                onTap: () => setSheetState(() =>
                                    condition = condition == c ? null : c),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),
                  CustomButton(
                    label: 'Apply Filters',
                    icon: Icons.tune_rounded,
                    onPressed: () {
                      setState(() {
                        _categoryFilter = category;
                        _availabilityFilter = availability;
                        _conditionFilter = condition;
                      });
                      Navigator.of(ctx).pop();
                    },
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

    return LiquidScaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              widget.onBack?.call();
            }
          },
        ),
        title: const Text('Equipment'),
        actions: [
          Center(
            child: GlassIconButton(
              size: 40,
              iconSize: 19,
              icon: Icons.sort_rounded,
              tooltip: 'Sort',
              active: _sort != _EquipmentSort.name,
              onTap: _openSortSheet,
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GlassIconButton(
                size: 40,
                iconSize: 19,
                icon: Icons.tune_rounded,
                tooltip: 'Filters',
                active: _hasActiveFilters,
                onTap: () => _openFilterSheet(categories),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${filtered.length} of ${appState.equipment.length}  ·  ${_sort.label}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  // ── Search ──────────────────────────────────────────────
                  GlassPanel(
                    blur: 0,
                    radius: AppRadius.pill,
                    padding: EdgeInsets.zero,
                    shadows: AppShadows.soft,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search equipment',
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
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),

                  // ── Category chips ──────────────────────────────────────
                  if (categories.isNotEmpty)
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        children: [
                          GlassChip(
                            label: 'All',
                            selected: _categoryFilter == null,
                            onTap: () => setState(() => _categoryFilter = null),
                          ),
                          const SizedBox(width: 8),
                          ...categories.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GlassChip(
                                label: c,
                                selected: _categoryFilter == c,
                                onTap: () =>
                                    setState(() => _categoryFilter = c),
                              ),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.94,
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
// Grid tile — glass surface with gradient icon and live stock.
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
    final ratio = equipment.totalQuantity == 0
        ? 0.0
        : equipment.availableQuantity / equipment.totalQuantity;

    return Pressable(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: EquipmentVisual(
                    equipment: equipment,
                    iconSize: 24,
                    iconColor: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _availabilityColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _availabilityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        equipment.availabilityStatus,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: _availabilityColor,
                        ),
                      ),
                    ],
                  ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                backgroundColor: AppColors.divider.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation<Color>(_availabilityColor),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text(
                  '${equipment.availableQuantity}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
        boxShadow: AppShadows.soft,
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
              child:
                  Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
