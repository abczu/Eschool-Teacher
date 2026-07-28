import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/contact/contactListCubit.dart';
import 'package:eschool_saas_staff/cubits/contact/contactStatsCubit.dart';
import 'package:eschool_saas_staff/models/contact.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:shimmer/shimmer.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  String searchQuery = "";
  String? _selectedSort = 'created_at:desc';

  String? _selectedType;
  String? _selectedStatus;

  // Enhanced color palette with soft maroon theme
  final Color _primaryColor = const Color(0xFF6B2C3E);
  final Color _lightColor = const Color(0xFF9B5D6D);
  final Color _accentColor = const Color(0xFFB17A8B);
  final Color _surfaceColor = const Color(0xFFFAF7F8);
  final Color _gradientStart = const Color(0xFF6B2C3E);
  final Color _gradientEnd = const Color(0xFF8B4A5D);

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _searchController = TextEditingController();
    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);

    // Load initial data with animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideAnimationController.forward();
      context.read<ContactListCubit>().getContacts(refresh: true);
      context.read<ContactStatsCubit>().getContactStats();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<ContactListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : _surfaceColor;
    final Color cardBgColor = isDark ? Theme.of(context).cardColor : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    bgColor,
                    bgColor,
                  ]
                : [
                    _surfaceColor,
                    _surfaceColor.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.9),
                  ],
          ),
        ),
        child: Column(
          children: [
            CustomModernAppBar(
              title: 'Kontak & Laporan',
              icon: Icons.contact_support_rounded,
              fabAnimationController: _fabAnimationController,
              primaryColor: _primaryColor,
              lightColor: _lightColor,
              showAddButton: true,
              onAddPressed: _showSubmitContactDialog,
              onBackPressed: () {
                _fabAnimationController.stop();
                Get.back();
              },
            ),
            // Scrollable content dengan semua elemen
            Expanded(
              child: _buildScrollableContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return BlocBuilder<ContactListCubit, ContactListState>(
      builder: (context, state) {
        if (state is ContactListLoading) {
          return RefreshIndicator(
            onRefresh: () => context.read<ContactListCubit>().refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Search and Filter Section (tetap tampil saat loading)
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _slideAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          50 * (1 - _slideAnimationController.value),
                        ),
                        child: Opacity(
                          opacity: _slideAnimationController.value,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: Column(
                              children: [
                                _buildEnhancedSearchBar(),
                                const SizedBox(height: 16),
                                _buildEnhancedFilterCard(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Stats Section (skeleton)
                SliverToBoxAdapter(
                  child: _buildSkeletonStatsSection(),
                ),
                // Contact List Skeleton
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SkeletonContactListItem(),
                      );
                    },
                    childCount: 6, // Show 6 skeleton items
                  ),
                ),
              ],
            ),
          );
        } else if (state is ContactListSuccess) {
          return RefreshIndicator(
            onRefresh: () => context.read<ContactListCubit>().refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Search and Filter Section
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _slideAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          50 * (1 - _slideAnimationController.value),
                        ),
                        child: Opacity(
                          opacity: _slideAnimationController.value,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: Column(
                              children: [
                                _buildEnhancedSearchBar(),
                                const SizedBox(height: 16),
                                _buildEnhancedFilterCard(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Stats Section
                SliverToBoxAdapter(
                  child: _buildEnhancedStatsSection(),
                ),
                // Contact List
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
                state.contacts.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == state.contacts.length) {
                              return state.hasMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox(height: 20);
                            }
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildContactItem(
                                  state.contacts[index], index),
                            );
                          },
                          childCount:
                              state.contacts.length + (state.hasMore ? 1 : 0),
                        ),
                      ),
              ],
            ),
          );
        } else if (state is ContactListFailure) {
          return CustomScrollView(
            slivers: [
              // Search and Filter Section (tetap tampil saat error)
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _slideAnimationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        50 * (1 - _slideAnimationController.value),
                      ),
                      child: Opacity(
                        opacity: _slideAnimationController.value,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          child: Column(
                            children: [
                              _buildEnhancedSearchBar(),
                              const SizedBox(height: 16),
                              _buildEnhancedFilterCard(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverFillRemaining(
                child: _buildErrorState(state.errorMessage),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEnhancedSearchBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBgColor = isDark ? Theme.of(context).cardColor : Colors.white;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? cardBgColor : null,
        gradient: isDark
            ? null
            : LinearGradient(
                colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : _primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari kontak, pesan, atau nama...',
          hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey[500] : Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: isDark ? _accentColor : _primaryColor,
              size: 24,
            ),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: _primaryColor, size: 20),
                    onPressed: () {
                      setState(() {
                        searchQuery = "";
                        _searchController.clear();
                      });
                      _applyFilters();
                    },
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : Colors.black),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        onSubmitted: (_) => _applyFilters(),
      ),
    )
        .animate()
        .shimmer(duration: 2000.ms, color: _accentColor.withValues(alpha: 0.3))
        .scale(begin: const Offset(0.95, 0.95), duration: 200.ms);
  }

  Widget _buildEnhancedFilterCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBgColor = isDark ? Theme.of(context).cardColor : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? cardBgColor : null,
        gradient: isDark
            ? null
            : LinearGradient(
                colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : _primaryColor.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [],
          ),
          Text(
            'Tipe Kontak',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEnhancedFilterChip(
                'Semua',
                Icons.all_inclusive_rounded,
                _selectedType == null,
                () {
                  setState(() => _selectedType = null);
                  _applyFilters();
                },
              ),
              _buildEnhancedFilterChip(
                'Pertanyaan',
                Icons.question_answer_sharp,
                _selectedType == 'inquiry',
                () {
                  setState(() => _selectedType = 'inquiry');
                  _applyFilters();
                },
              ),
              _buildEnhancedFilterChip(
                'Laporan',
                Icons.report_problem_outlined,
                _selectedType == 'report',
                () {
                  setState(() => _selectedType = 'report');
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Status',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEnhancedFilterChip(
                'Baru',
                Icons.new_releases_rounded,
                _selectedStatus == 'new',
                () {
                  setState(() => _selectedStatus = 'new');
                  _applyFilters();
                },
              ),
              _buildEnhancedFilterChip(
                'Dibalas',
                Icons.reply_rounded,
                _selectedStatus == 'replied',
                () {
                  setState(() => _selectedStatus = 'replied');
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey.shade800 : _accentColor.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSort,
              dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
              decoration: InputDecoration(
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child:
                      Icon(Icons.sort_rounded, color: isDark ? _accentColor : _primaryColor, size: 20),
                ),
                labelText: 'Urutkan Berdasarkan',
                labelStyle: GoogleFonts.poppins(
                  color: isDark ? Colors.white70 : _primaryColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : Colors.black,
              ),
              items: [
                DropdownMenuItem(
                  value: 'created_at:desc',
                  child: Row(
                    children: [
                      Text('Terbaru', style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'created_at:asc',
                  child: Row(
                    children: [
                      Text('Terlama', style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedSort = value);
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSkeletonStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSkeletonStatCard(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSkeletonStatCard(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSkeletonStatCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonStatCard() {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimationController.value * 0.02),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 24,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    )
        .animate(delay: 0.ms)
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.8, 0.8))
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildEnhancedStatsSection() {
    return BlocBuilder<ContactStatsCubit, ContactStatsState>(
      builder: (context, state) {
        if (state is ContactStatsSuccess) {
          return Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Total Kontak',
                    state.stats.totalContacts.toString(),
                    Icons.contact_page_rounded,
                    _primaryColor,
                    _gradientStart,
                    _gradientEnd,
                    0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Baru',
                    state.stats.newContacts.toString(),
                    Icons.check_circle_rounded,
                    const Color(0xFF1E40AF), // Biru pekat yang sama
                    const Color(0xFF1E40AF),
                    const Color(0xFF3B82F6),
                    100,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEnhancedStatCard(
                    'Dibalas',
                    state.stats.repliedContacts.toString(),
                    Icons.reply_rounded,
                    const Color(0xFF059669), // Hijau pekat yang sama
                    const Color(0xFF059669),
                    const Color(0xFF10B981),
                    200,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEnhancedStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color gradientStart,
    Color gradientEnd,
    int animationDelay,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseAnimationController.value * 0.02),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    )
        .animate(delay: animationDelay.ms)
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.8, 0.8))
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildContactItem(Contact contact, int index) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBgColor = isDark ? Theme.of(context).cardColor : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : _accentColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : _primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToContactDetail(contact),
          splashColor: _primaryColor.withValues(alpha: 0.08),
          highlightColor: _accentColor.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section dengan layout yang lebih terorganisir
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon kontainer dengan design yang lebih clean
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: contact.isInquiry
                              ? [
                                  const Color(0xFF8B6B8F)
                                      .withValues(alpha: 0.15),
                                  const Color(0xFFA67C96)
                                      .withValues(alpha: 0.1),
                                ]
                              : [
                                  const Color(0xFFD4A574)
                                      .withValues(alpha: 0.15),
                                  const Color(0xFFE8B893)
                                      .withValues(alpha: 0.1),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: contact.isInquiry
                              ? const Color(0xFF8B6B8F).withValues(alpha: 0.2)
                              : const Color(0xFFD4A574).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        contact.isInquiry
                            ? Icons.question_answer_sharp
                            : Icons.report_problem_rounded,
                        color: contact.isInquiry
                            ? const Color(0xFF8B6B8F)
                            : const Color(0xFFD4A574),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content section dengan spacing yang lebih baik
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject dengan typography yang lebih clean
                          Text(
                            contact.subject,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : _primaryColor,
                              height: 1.4,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // User info dengan format yang lebih jelas
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status chip dengan posisi yang lebih baik
                    _buildModernStatusChip(contact.status),
                  ],
                ),
                const SizedBox(height: 16),

                // Message container dengan design yang lebih clean dan readable
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : _accentColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.1) : _primaryColor.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header pesan yang lebih minimal
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                              color: isDark ? Colors.white70 : _primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pesan',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : _primaryColor,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const Spacer(),
                          // Timestamp di header pesan
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900 : _surfaceColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDateTime(contact.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDark ? Colors.grey[400] : _lightColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Isi pesan dengan typography yang lebih baik
                      Text(
                        contact.message,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Indikator jika pesan terpotong
                      if (contact.message.length > 150)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... baca selengkapnya',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFAC3B5C) : _primaryColor,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Reply preview if exists
                if (contact.replies != null && contact.replies!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF064E3B).withValues(alpha: 0.2),
                                const Color(0xFF065F46).withValues(alpha: 0.15),
                              ]
                            : [
                                const Color(0xFF059669).withValues(alpha: 0.05),
                                const Color(0xFF10B981).withValues(alpha: 0.03),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: isDark ? 0.3 : 0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.reply_rounded,
                                size: 14,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Balasan (${contact.replies!.length})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                                letterSpacing: -0.1,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDateTime(
                                    contact.replies!.last.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          contact.replies!.last.reply,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contact.replies!.last.adminName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                contact.replies!.last.adminName!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF059669)
                                      .withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.1, end: 0)
                else
                  // Debug: Show if no replies
                  const SizedBox.shrink(),

                const SizedBox(height: 16),

                // Footer dengan layout yang lebih terorganisir
                Row(
                  children: [
                    // Type badge dengan design yang lebih compact
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: contact.isInquiry
                            ? const Color(0xFF8B6B8F).withValues(alpha: 0.1)
                            : const Color(0xFFD4A574).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: contact.isInquiry
                              ? const Color(0xFF8B6B8F).withValues(alpha: 0.2)
                              : const Color(0xFFD4A574).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            contact.isInquiry
                                ? Icons.help_center_rounded
                                : Icons.report_gmailerrorred_rounded,
                            size: 12,
                            color: contact.isInquiry
                                ? const Color(0xFF8B6B8F)
                                : const Color(0xFFD4A574),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contact.typeDisplayName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: contact.isInquiry
                                  ? const Color(0xFF8B6B8F)
                                  : const Color(0xFFD4A574),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Action button untuk membuka detail
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _lightColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _navigateToContactDetail(contact),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Detail',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack);
  }

  Widget _buildModernStatusChip(String status) {
    Color primaryColor;
    Color backgroundColor;
    String text;
    IconData icon;

    switch (status) {
      case 'new':
        primaryColor = const Color(0xFF1E40AF); // Biru pekat yang jelas
        backgroundColor = const Color(0xFF1E40AF).withValues(alpha: 0.15);
        text = 'Baru';
        icon = Icons.check_circle_rounded;
        break;
      case 'replied':
        primaryColor = const Color(0xFF059669); // Hijau pekat yang jelas
        backgroundColor = const Color(0xFF059669).withValues(alpha: 0.15);
        text = 'Dibalas';
        icon = Icons.done_all_rounded;
        break;
      case 'closed':
        primaryColor = const Color(0xFF9B8A8A);
        backgroundColor = const Color(0xFF9B8A8A).withValues(alpha: 0.12);
        text = 'Ditutup';
        icon = Icons.lock_rounded;
        break;
      default:
        primaryColor = const Color(0xFF9B8A8A);
        backgroundColor = const Color(0xFF9B8A8A).withValues(alpha: 0.12);
        text = status;
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.9, 0.9)).fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withValues(alpha: 0.1),
                    _accentColor.withValues(alpha: 0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.contact_support_rounded,
                size: 80,
                color: isDark ? Colors.white : _primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Belum Ada Kontak',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : _primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Belum ada inquiry atau laporan yang masuk ke sistem.\nMulai terima kontak dari pengguna!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : _lightColor,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _showSubmitContactDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _lightColor],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Tambah Kontak Baru',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.8, 0.8))
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '⚠️ Terjadi Kesalahan',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _lightColor],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.read<ContactListCubit>().refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.8, 0.8))
        .shake(duration: 500.ms);
  }

  Widget _buildEnhancedFilterChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [_primaryColor, _lightColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : (isDark ? Colors.grey.shade900 : _surfaceColor),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _primaryColor
                : (isDark ? Colors.grey.shade800 : _accentColor.withValues(alpha: 0.3)),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : _primaryColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : _primaryColor),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(target: isSelected ? 1 : 0)
        .scale(begin: const Offset(0.95, 0.95))
        .shimmer(duration: 1000.ms, color: Colors.white.withValues(alpha: 0.5));
  }

  void _showSubmitContactDialog() async {
    final result =
        await Navigator.pushNamed(context, Routes.submitContactScreen);
    if (result == true) {
      if (!mounted) return;
      context.read<ContactListCubit>().refresh();
    }
  }

  void _applyFilters() {
    context.read<ContactListCubit>().getContacts(
          type: _selectedType,
          status: _selectedStatus,
          search:
              _searchController.text.isNotEmpty ? _searchController.text : null,
          sort: _selectedSort,
          refresh: true,
        );
  }

  void _navigateToContactDetail(Contact contact) async {
    final result = await Get.toNamed(
      Routes.contactDetailScreen,
      arguments: contact.id,
    );

    // Refresh contact list when returning from detail screen
    // Only refresh if user has sent a reply (result == true)
    if (result == true) {
      if (!mounted) return;
      // Refresh contact list to show updated replies
      context.read<ContactListCubit>().getContacts(
            type: _selectedType,
            status: _selectedStatus,
            search: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
            sort: _selectedSort,
            refresh: true,
          );
      // Refresh stats
      context.read<ContactStatsCubit>().getContactStats();
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      // Try to parse as ISO 8601 format first
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      // If parsing fails, assume it's already formatted
      // Check if it's already in the expected format
      if (dateTimeString.contains('/')) {
        return dateTimeString;
      }
      // If not, return as is
      return dateTimeString;
    }
  }
}
