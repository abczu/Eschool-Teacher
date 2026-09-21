import 'package:eschool_saas_staff/cubits/leave/generalPermissionCubit.dart';
import 'package:eschool_saas_staff/data/models/auth/permissionDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/permissionDetailsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:intl/intl.dart';

class GeneralPermissionScreen extends StatefulWidget {
  const GeneralPermissionScreen({super.key});

  static Widget getRouteInstance() => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => GeneralPermissionCubit(),
          ),
        ],
        child: const GeneralPermissionScreen(),
      );

  @override
  State<GeneralPermissionScreen> createState() =>
      _GeneralPermissionScreenState();
}

class _GeneralPermissionScreenState extends State<GeneralPermissionScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDateTime = DateTime.now();
  bool _isSortNewest = true; // true = Terbaru, false = Terlama

  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _maroonLight = const Color(0xFFAA6976);

  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      getLeaves();
    });

    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void getLeaves() {
    LeaveDayType leaveDayType = LeaveDayType.today;
    debugPrint("Fetching leaves for date: $_selectedDateTime");
    debugPrint(
        "Formatted date: ${_selectedDateTime.toIso8601String().split('T')[0]}");

    context
        .read<GeneralPermissionCubit>()
        .getGeneralLeaves(leaveDayType: leaveDayType, date: _selectedDateTime);
  }

  List<PermissionDetails> _getSortedLeaves(List<PermissionDetails> leaves) {
    final list = List<PermissionDetails>.from(leaves);
    list.sort((a, b) {
      final aLeave = a.leaves.isNotEmpty ? a.leaves.last : null;
      final bLeave = b.leaves.isNotEmpty ? b.leaves.last : null;

      final aId = aLeave?.id ?? a.id ?? 0;
      final bId = bLeave?.id ?? b.id ?? 0;

      DateTime? dateA;
      DateTime? dateB;

      try {
        if (aLeave?.fromDate != null) {
          dateA = DateTime.tryParse(aLeave!.fromDate!) ??
              DateFormat('dd-MM-yyyy').tryParse(aLeave.fromDate!);
        }
      } catch (_) {}

      try {
        if (bLeave?.fromDate != null) {
          dateB = DateTime.tryParse(bLeave!.fromDate!) ??
              DateFormat('dd-MM-yyyy').tryParse(bLeave.fromDate!);
        }
      } catch (_) {}

      if (dateA != null && dateB != null && !dateA.isAtSameMomentAs(dateB)) {
        return _isSortNewest ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      }

      return _isSortNewest ? bId.compareTo(aId) : aId.compareTo(bId);
    });
    return list;
  }

  Widget _buildAppBar() {
    return CustomModernAppBar(
      title: Utils.getTranslatedLabel(permissionStudentKey),
      icon: Icons.person_outline_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      height: 150,
      onBackPressed: () => Navigator.of(context).pop(),
      tabBuilder: (context) => SizedBox(
        height: 48,
        child: Row(
          children: [
            // Date picker button
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final selectedDate = await Utils.openDatePicker(
                      context: context,
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                    );

                    if (selectedDate != null) {
                      _selectedDateTime = selectedDate;
                      setState(() {});
                      getLeaves();
                    }
                  },
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            Utils.formatDate(_selectedDateTime),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Vertical Divider
            Container(
              height: 22,
              width: 1,
              color: Colors.white.withValues(alpha: 0.25),
            ),

            // Sort Filter (Terbaru / Terlama)
            PopupMenuButton<bool>(
              initialValue: _isSortNewest,
              onSelected: (val) {
                setState(() {
                  _isSortNewest = val;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A2C)
                  : Colors.white,
              elevation: 8,
              itemBuilder: (context) => [
                PopupMenuItem<bool>(
                  value: true,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 18,
                        color: _isSortNewest ? _maroonPrimary : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Terbaru",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _isSortNewest
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: _isSortNewest
                              ? _maroonPrimary
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<bool>(
                  value: false,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: !_isSortNewest ? _maroonPrimary : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Terlama",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: !_isSortNewest
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: !_isSortNewest
                              ? _maroonPrimary
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sort_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSortNewest ? "Terbaru" : "Terlama",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                    BlocBuilder<GeneralPermissionCubit, GeneralPermissionState>(
                  builder: (context, state) {
                    if (state is GeneralPermissionFetchSuccess) {
                      final sortedLeaves = _getSortedLeaves(state.leaves);

                      if (sortedLeaves.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_ind_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              CustomTextContainer(
                                textKey: Utils.getTranslatedLabel(
                                    noStudentPermissionKey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tanggal: ${Utils.formatDate(_selectedDateTime)}',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: getLeaves,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Perbarui Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _maroonPrimary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 155,
                            bottom: 30,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Utils.getTranslatedLabel(
                                          permissionStudentKey),
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : _maroonPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Izin siswa tanggal ${Utils.formatDate(_selectedDateTime)} (${sortedLeaves.length} siswa)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 350.ms).slideY(
                                  begin: -0.05,
                                  end: 0,
                                  curve: Curves.easeOutQuad),

                              // Vertical List of Permission Cards
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                itemCount: sortedLeaves.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  return Animate(
                                    effects: [
                                      FadeEffect(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        delay: Duration(
                                            milliseconds: 40 * index),
                                      ),
                                      SlideEffect(
                                        begin: const Offset(0, 0.04),
                                        end: Offset.zero,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        delay: Duration(
                                            milliseconds: 40 * index),
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ],
                                    child: PermissionDetailsContainer(
                                      permissionDetails: sortedLeaves[index],
                                      isCompact: false,
                                      onPermissionUpdated: getLeaves,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    } else if (state is GeneralPermissionFetchFailure) {
                      return Center(
                        child: CustomErrorWidget(
                          message: ErrorMessageUtils.getReadableErrorMessage(
                              state.errorMessage),
                          onRetry: getLeaves,
                          primaryColor: _maroonPrimary,
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 155,
                          bottom: 25,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title section skeleton
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              child: Shimmer.fromColors(
                                baseColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                highlightColor: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade100,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 24,
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade700
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 14,
                                      width: 300,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade700
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Permission containers skeleton
                            Column(
                              children: List.generate(5, (index) {
                                return Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Theme.of(context).cardColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isDark
                                        ? Border.all(
                                            color: Colors.grey.shade800)
                                        : null,
                                    boxShadow: isDark
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                  ),
                                  child: Shimmer.fromColors(
                                    baseColor: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                    highlightColor: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade100,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Student info section
                                          Row(
                                            children: [
                                              // Avatar
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.grey.shade700
                                                      : Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Student details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 16,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors
                                                                .grey.shade700
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      height: 14,
                                                      width: 120,
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors
                                                                .grey.shade700
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Status badge
                                              Container(
                                                width: 80,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.grey.shade700
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 16),

                                          // Permission details section
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.grey.shade900
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Date range
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors
                                                                .grey.shade700
                                                            : Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      height: 14,
                                                      width: 150,
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors
                                                                .grey.shade700
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Reason
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 16,
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors
                                                                .grey.shade700
                                                            : Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Container(
                                                        height: 14,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isDark
                                                              ? Colors
                                                                  .grey.shade700
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          _buildAppBar(),
        ],
      ),
    );
  }
}
