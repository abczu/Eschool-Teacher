import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Dummy Class representing Student Leave Requests for quick standalone testing / integration
class StudentLeaveRequestMock {
  final int id;
  final String studentName;
  final String studentClass;
  final int attendanceNumber;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final String date;
  final bool hasAttachment;
  final String reason;

  StudentLeaveRequestMock({
    required this.id,
    required this.studentName,
    required this.studentClass,
    required this.attendanceNumber,
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
    required this.date,
    required this.hasAttachment,
    required this.reason,
  });
}

class StudentLeaveApprovalCarouselScreen extends StatefulWidget {
  final List<StudentLeaveRequestMock>? leaveRequests;
  final Function(StudentLeaveRequestMock)? onApprove;
  final Function(StudentLeaveRequestMock)? onReject;
  final VoidCallback? onBackPressed;

  const StudentLeaveApprovalCarouselScreen({
    super.key,
    this.leaveRequests,
    this.onApprove,
    this.onReject,
    this.onBackPressed,
  });

  @override
  State<StudentLeaveApprovalCarouselScreen> createState() =>
      _StudentLeaveApprovalCarouselScreenState();
}

class _StudentLeaveApprovalCarouselScreenState
    extends State<StudentLeaveApprovalCarouselScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  double _pageOffset = 0.0;

  // The primary color from Eschool-Teacher design
  final Color _indigoPrimary = const Color(0xFF6366F1);
  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _successColor = const Color(0xFF10B981);

  // Default mock data if none is provided via constructor
  late List<StudentLeaveRequestMock> _listRequests;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    });

    _listRequests = widget.leaveRequests ??
        [
          StudentLeaveRequestMock(
            id: 1,
            studentName: "Gilang Pane",
            studentClass: "X ELIN",
            attendanceNumber: 10,
            status: "Sakit",
            statusColor: const Color(0xFFE11D48),
            statusBgColor: const Color(0xFFFFE4E6),
            date: "16-07-2026",
            hasAttachment: true,
            reason: "Mengalami demam tinggi dan disarankan dokter beristirahat.",
          ),
          StudentLeaveRequestMock(
            id: 2,
            studentName: "Andi Saputra",
            studentClass: "X TKJ 1",
            attendanceNumber: 3,
            status: "Izin",
            statusColor: const Color(0xFFD97706),
            statusBgColor: const Color(0xFFFEF3C7),
            date: "17-07-2026",
            hasAttachment: false,
            reason: "Menghadiri acara pernikahan kakak kandung di luar kota.",
          ),
          StudentLeaveRequestMock(
            id: 3,
            studentName: "Riana Lestari",
            studentClass: "XI RPL 2",
            attendanceNumber: 27,
            status: "Sakit",
            statusColor: const Color(0xFFE11D48),
            statusBgColor: const Color(0xFFFFE4E6),
            date: "18-07-2026",
            hasAttachment: true,
            reason: "Sakit cacar air, butuh isolasi mandiri selama 5 hari.",
          ),
        ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleApprove(StudentLeaveRequestMock request) {
    if (widget.onApprove != null) {
      widget.onApprove!(request);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Izin ${request.studentName} disetujui!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleReject(StudentLeaveRequestMock request) {
    if (widget.onReject != null) {
      widget.onReject!(request);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Izin ${request.studentName} ditolak!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Persetujuan Izin Siswa",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: _maroonPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: _listRequests.isEmpty
          ? Center(
              child: Text(
                "Tidak ada permohonan izin",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            )
          : Column(
              children: [
                // Top Progress indicator
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Daftar Permohonan Hari Ini",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _maroonPrimary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_currentPage + 1} / ${_listRequests.length}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _maroonPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Main Carousel area
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _listRequests.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _listRequests[index];

                      // Custom tinder-like/carousel scale & translate animation logic
                      double scale = 1.0;
                      double rotation = 0.0;
                      double opacity = 1.0;

                      if (_pageOffset >= index - 1 && _pageOffset <= index + 1) {
                        final diff = (_pageOffset - index).abs();
                        // Active card is scale 1.0, surrounding cards scale down to 0.9
                        scale = 1.0 - (diff * 0.08);
                        opacity = 1.0 - (diff * 0.3);
                        rotation = (index - _pageOffset) * 0.05; // Gentle tilt
                      } else {
                        scale = 0.92;
                        opacity = 0.7;
                      }

                      return Transform.translate(
                        offset: Offset(0, (1.0 - scale) * 100),
                        child: Transform.rotate(
                          angle: rotation,
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: _buildLeaveCard(item),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildLeaveCard(StudentLeaveRequestMock item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top Section of Card (Headers)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: item.statusBgColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: item.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.status,
                          style: GoogleFonts.poppins(
                            color: item.statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Clip Icon / Attachment status
                  if (item.hasAttachment)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        color: _maroonPrimary,
                        size: 18,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),

            // Profile & Name Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Decorative Placeholder Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: _maroonPrimary.withAlpha(15),
                      child: Text(
                        item.studentName.isNotEmpty
                            ? item.studentName.substring(0, 1).toUpperCase()
                            : "S",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _maroonPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Student Name (large, bold)
                    Text(
                      item.studentName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Compact metadata chips (Class and Attendance)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadgeChip("Kelas: ${item.studentClass}"),
                        const SizedBox(width: 8),
                        _buildBadgeChip("Absen: ${item.attendanceNumber}"),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Leave Date
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.date_range_rounded,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            item.date,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reason Snippet
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          item.reason,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions (Approve / Reject buttons)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Reject Action Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleReject(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Tolak",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Approve Action Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApprove(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Setujui",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}
