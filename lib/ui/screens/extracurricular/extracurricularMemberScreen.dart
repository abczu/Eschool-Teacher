import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'package:eschool_saas_staff/cubits/extracurricularMember/extracurricularMemberCubit.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularMember.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/extracurricular/extracurricularMemberListCard.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';

class ExtracurricularMemberScreen extends StatefulWidget {
  const ExtracurricularMemberScreen({super.key});

  @override
  State<ExtracurricularMemberScreen> createState() =>
      _ExtracurricularMemberScreenState();
}

class _ExtracurricularMemberScreenState
    extends State<ExtracurricularMemberScreen> with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late TextEditingController _searchController;

  // Theme colors - Dynamic brightened maroon/coral palette
  Color get _maroonPrimary => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE53935) // Bright maroon/red for dark mode
      : const Color(0xFF8B1F41); // Standard app deep maroon for light mode

  Color get _maroonLight => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFEF5350) // Bright pastel maroon for dark mode
      : const Color(0xFFAC3B5C); // Standard highlight maroon for light mode

  // Filter state
  String? _selectedStatusFilter;
  List<ExtracurricularMember> _allMembers = [];
  List<ExtracurricularMember> _filteredMembers = [];

  // Filter options
  final List<Map<String, String>> _statusFilters = [
    {'key': '', 'label': 'Semua Status'},
    {'key': '0', 'label': 'Menunggu Persetujuan'},
    {'key': '1', 'label': 'Disetujui'},
    {'key': '2', 'label': 'Ditolak'},
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _searchController = TextEditingController();

    // Start animations
    _fabAnimationController.forward();

    // Load data
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ExtracurricularMemberCubit>().getExtracurricularMembers();
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<ExtracurricularMember> filtered = _allMembers;

    // Apply status filter
    if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
      filtered = filtered
          .where((member) => member.status == _selectedStatusFilter)
          .toList();
    }

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        final name = member.studentName?.toLowerCase() ?? '';
        final nisn = member.studentNisn?.toLowerCase() ?? '';
        final className = member.className?.toLowerCase() ?? '';
        return name.contains(searchQuery) ||
            nisn.contains(searchQuery) ||
            className.contains(searchQuery);
      }).toList();
    }

    setState(() {
      _filteredMembers = filtered;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter Status',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _maroonPrimary,
          ),
        ),
        content: RadioGroup<String>(
          groupValue: _selectedStatusFilter ?? '',
          onChanged: (value) {
            setState(() {
              _selectedStatusFilter = value == '' ? null : value;
            });
            Navigator.pop(context);
            _applyFilters();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _statusFilters.map((filter) {
              return RadioListTile<String>(
                title: Text(
                  filter['label']!,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                value: filter['key']!,
                activeColor: _maroonPrimary,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(ExtracurricularMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Aksi Anggota',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _maroonPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama: ${member.studentName ?? '-'}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              'NISN: ${member.studentNisn ?? '-'}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              'Kelas: ${member.className ?? '-'}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              'Status: ${member.statusText}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
        actions: [
          if (member.isPending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectMember(member);
              },
              child: Text(
                'Tolak',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveMember(member);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _maroonPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Setujui',
                style: GoogleFonts.poppins(),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _approveMember(ExtracurricularMember member) {
    if (member.id != null) {
      context.read<ExtracurricularMemberCubit>().approveMember(member.id!);
    }
  }

  void _rejectMember(ExtracurricularMember member) {
    if (member.id != null) {
      context.read<ExtracurricularMemberCubit>().rejectMember(member.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: CustomModernAppBar(
        title: 'Daftar Anggota',
        icon: Icons.people_rounded,
        fabAnimationController: _fabAnimationController,
        primaryColor: const Color(0xFF8B1F41),
        lightColor: const Color(0xFFAC3B5C),
        onBackPressed: () {
          _fabAnimationController.stop();
          Get.back();
        },
        showFilterButton: true,
        onFilterPressed: _showFilterDialog,
        filterActive: _selectedStatusFilter != null,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: EdgeInsets.only(
              top: Utils.appContentTopScrollPadding(context: context) + 20,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _maroonPrimary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _applyFilters(),
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama, NISN, atau kelas...',
                hintStyle: GoogleFonts.poppins(
                  color: isDark ? Colors.grey[400] : Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _maroonPrimary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Member list
          Expanded(
            child: BlocConsumer<ExtracurricularMemberCubit,
                ExtracurricularMemberState>(
              listener: (context, state) {
                debugPrint(
                    ' [MEMBER SCREEN] State changed: ${state.runtimeType}');

                if (state is ExtracurricularMemberSuccess) {
                  debugPrint(
                      ' [MEMBER SCREEN] Success state with ${state.members?.length ?? 0} members');

                  if (state.members != null) {
                    _allMembers = state.members!;
                    _applyFilters();
                    debugPrint(
                        ' [MEMBER SCREEN] Applied filters, filtered count: ${_filteredMembers.length}');
                  }

                  // Show success message for approve/reject actions
                  if (state.message.contains('disetujui') ||
                      state.message.contains('ditolak')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.message,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: _maroonPrimary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }

                if (state is ExtracurricularMemberFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ExtracurricularMemberLoading) {
                  return _buildLoadingSkeleton();
                }

                if (state is ExtracurricularMemberFailure) {
                  return ErrorContainer(
                    errorMessage: state.errorMessage,
                    onTapRetry: () {
                      context
                          .read<ExtracurricularMemberCubit>()
                          .getExtracurricularMembers();
                    },
                  );
                }

                if (_filteredMembers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outlined,
                            size: 80,
                            color: _maroonPrimary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchController.text.isNotEmpty ||
                                    _selectedStatusFilter != null
                                ? "Tidak ada anggota yang sesuai dengan filter"
                                : "Belum ada anggota ekstrakurikuler",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _searchController.text.isNotEmpty ||
                                    _selectedStatusFilter != null
                                ? "Coba ubah filter atau kata kunci pencarian"
                                : "Belum ada siswa yang mendaftar ekstrakurikuler",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 10),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Header with member count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              color: _maroonPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Daftar Anggota",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[800],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _maroonPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _maroonPrimary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "${_filteredMembers.length} Anggota",
                                style: GoogleFonts.poppins(
                                  color: _maroonPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Member list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          return AnimatedBuilder(
                            animation: _fabAnimationController,
                            builder: (context, child) {
                              // Stagger the animations
                              final delay = (index * 0.1).clamp(0.0, 1.0);
                              final delayedAnimation =
                                  Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _fabAnimationController,
                                  curve: Interval(delay, 1.0,
                                      curve: Curves.easeOut),
                                ),
                              );

                              return Transform.translate(
                                offset: Offset(
                                    0, 20 * (1.0 - delayedAnimation.value)),
                                child: Opacity(
                                  opacity: delayedAnimation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ExtracurricularMemberListCard(
                                member: member,
                                onTap: () => _showActionDialog(member),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color shimmerBase = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final Color shimmerHighlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;
    final Color cardBg = isDark ? Theme.of(context).cardColor : Colors.white;
    final Color skeletonContentColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Shimmer.fromColors(
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: skeletonContentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: skeletonContentColor,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 150,
                        color: skeletonContentColor,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 120,
                        color: skeletonContentColor,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: skeletonContentColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
