import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/violation/violationRoleCheck.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViolationFilterBottomSheet extends StatefulWidget {
  final bool isHomeroomView;
  final List<ClassSection>? allClasses;
  final List<HomeroomClass>? homeroomClasses;
  final int? currentClassId;
  final String? currentSortBy;
  final String? currentFilter;
  final Function({
    int? classId,
    String? sortBy,
    String? filter,
  }) onApply;

  const ViolationFilterBottomSheet({
    super.key,
    required this.isHomeroomView,
    this.allClasses,
    this.homeroomClasses,
    this.currentClassId,
    this.currentSortBy,
    this.currentFilter,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required bool isHomeroomView,
    List<ClassSection>? allClasses,
    List<HomeroomClass>? homeroomClasses,
    int? currentClassId,
    String? currentSortBy,
    String? currentFilter,
    required Function({
      int? classId,
      String? sortBy,
      String? filter,
    }) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ViolationFilterBottomSheet(
        isHomeroomView: isHomeroomView,
        allClasses: allClasses,
        homeroomClasses: homeroomClasses,
        currentClassId: currentClassId,
        currentSortBy: currentSortBy,
        currentFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ViolationFilterBottomSheet> createState() =>
      _ViolationFilterBottomSheetState();
}

class _ViolationFilterBottomSheetState
    extends State<ViolationFilterBottomSheet> {
  int? _selectedClassId;
  late String _selectedSortBy;
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.currentClassId;
    _selectedSortBy = widget.currentSortBy ??
        (widget.isHomeroomView ? 'attendance_number' : 'highest_points');
    _selectedFilter = widget.currentFilter ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filter & Urutkan",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedClassId = null;
                    _selectedSortBy = widget.isHomeroomView
                        ? 'attendance_number'
                        : 'highest_points';
                    _selectedFilter = 'all';
                  });
                },
                child: Text(
                  "Reset",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // 1. Filter Kelas
          Text(
            "Pilih Kelas / Rombel",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _buildClassSelectionChips(primaryColor, isDark),

          // 2. Filter Status Siswa (Hanya untuk Wali Kelas)
          if (widget.isHomeroomView) ...[
            const SizedBox(height: 18),
            Text(
              "Status Pelanggaran",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: "Semua Siswa",
                  value: "all",
                  groupValue: _selectedFilter,
                  onSelected: (val) => setState(() => _selectedFilter = val),
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: "Ada Poin Pelanggaran",
                  value: "with_points",
                  groupValue: _selectedFilter,
                  onSelected: (val) => setState(() => _selectedFilter = val),
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: "Bersih (0 Poin)",
                  value: "clean",
                  groupValue: _selectedFilter,
                  onSelected: (val) => setState(() => _selectedFilter = val),
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),
          // 3. Urutkan Berdasarkan
          Text(
            "Urutkan Berdasarkan",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.isHomeroomView
                ? [
                    _buildFilterChip(
                      label: "Nomor Absen",
                      value: "attendance_number",
                      groupValue: _selectedSortBy,
                      onSelected: (val) =>
                          setState(() => _selectedSortBy = val),
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      label: "Abjad (A - Z)",
                      value: "alphabetical",
                      groupValue: _selectedSortBy,
                      onSelected: (val) =>
                          setState(() => _selectedSortBy = val),
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      label: "Poin Tertinggi",
                      value: "highest_points",
                      groupValue: _selectedSortBy,
                      onSelected: (val) =>
                          setState(() => _selectedSortBy = val),
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ]
                : [
                    _buildFilterChip(
                      label: "Poin Tertinggi",
                      value: "highest_points",
                      groupValue: _selectedSortBy,
                      onSelected: (val) =>
                          setState(() => _selectedSortBy = val),
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      label: "Poin Terendah",
                      value: "lowest_points",
                      groupValue: _selectedSortBy,
                      onSelected: (val) =>
                          setState(() => _selectedSortBy = val),
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      label: "Abjad (A - Z)",
                      value: "alphabetical",
                      groupValue: _selectedSortBy,
                      onSelected: (val) =>
                          setState(() => _selectedSortBy = val),
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    _buildFilterChip(
                      label: "Terbaru",
                      value: "latest",
                      groupValue: _selectedSortBy,
                      onSelected: (val) =>
                          setState(() => _selectedSortBy = val),
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                  ],
          ),

          const SizedBox(height: 24),
          // Tombol Terapkan
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onApply(
                  classId: _selectedClassId,
                  sortBy: _selectedSortBy,
                  filter: _selectedFilter,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                "Terapkan Filter",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelectionChips(Color primaryColor, bool isDark) {
    if (widget.isHomeroomView) {
      final classes = widget.homeroomClasses ?? [];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip(
            label: "Semua Kelas Saya",
            value: null,
            groupValue: _selectedClassId,
            onSelected: (val) => setState(() => _selectedClassId = null),
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          ...classes.map((c) => _buildFilterChip(
                label: c.className,
                value: c.classId,
                groupValue: _selectedClassId,
                onSelected: (val) => setState(() => _selectedClassId = val),
                primaryColor: primaryColor,
                isDark: isDark,
              )),
        ],
      );
    } else {
      final classes = widget.allClasses ?? [];
      return SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              label: "Semua Kelas",
              value: null,
              groupValue: _selectedClassId,
              onSelected: (val) => setState(() => _selectedClassId = null),
              primaryColor: primaryColor,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            ...classes.map((c) {
              final name = c.fullName ?? c.name ?? "Kelas ${c.id}";
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  label: name,
                  value: c.id,
                  groupValue: _selectedClassId,
                  onSelected: (val) => setState(() => _selectedClassId = val),
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
              );
            }),
          ],
        ),
      );
    }
  }

  Widget _buildFilterChip<T>({
    required String label,
    required T value,
    required T groupValue,
    required Function(T) onSelected,
    required Color primaryColor,
    required bool isDark,
  }) {
    final bool isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      selectedColor: primaryColor,
      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white24 : Colors.grey.shade300),
        ),
      ),
      showCheckmark: false,
    );
  }
}
