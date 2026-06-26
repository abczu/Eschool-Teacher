import 'dart:math';
import 'package:eschool_saas_staff/cubits/fee/downloadStudentFeeReceiptCubit.dart';
import 'package:eschool_saas_staff/data/models/fee/payment.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Constant needed for fee label translation
const String totalFeeKey = "totalFee";

class StudentPaidFeeDetailsContainer extends StatefulWidget {
  final StudentDetails studentDetails;
  final double compolsoryFeeAmount;
  final double optionalFeeAmount;
  final int index;
  final Color maroonPrimary;
  final Color maroonLight;

  const StudentPaidFeeDetailsContainer({
    super.key,
    required this.studentDetails,
    required this.compolsoryFeeAmount,
    required this.optionalFeeAmount,
    required this.index,
    required this.maroonPrimary,
    required this.maroonLight,
  });

  @override
  State<StudentPaidFeeDetailsContainer> createState() =>
      _StudentPaidFeeDetailsContainerState();
}

class _StudentPaidFeeDetailsContainerState
    extends State<StudentPaidFeeDetailsContainer>
    with TickerProviderStateMixin {
  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: tileCollapsedDuration);

  // We only need these two animations
  late final Animation<double> _opacityAnimation =
      Tween<double>(begin: 0, end: 1.0).animate(CurvedAnimation(
          parent: _animationController, curve: const Interval(0.5, 1.0)));

  late final Animation<double> _iconAngleAnimation =
      Tween<double>(begin: 0, end: 180).animate(CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOut));

  String formatRupiah(double amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _downloadFeeReceipt() {
    // Get all payment history records
    final List<PaymentHistory> paymentHistory =
        widget.studentDetails.paymentHistory ??
            widget.studentDetails.paidFeeDetails?.paymentHistory ??
            [];

    // Validate that we have payment records
    if (paymentHistory.isEmpty) {
      Utils.showSnackBar(
        message: "No payment records found for this student",
        context: context,
      );
      return;
    }

    // Extract payment history IDs
    final List<int> paymentHistoryIds =
        paymentHistory.map((payment) => payment.id).toList();

    if (paymentHistoryIds.isEmpty) {
      Utils.showSnackBar(
        message: "Invalid payment records found",
        context: context,
      );
      return;
    }

    Get.dialog(
      BlocProvider(
        create: (context) => DownloadStudentFeeReceiptCubit(),
        child: _downloadFeesReceiptDialog(paymentHistoryIds),
      ),
    );
  }

  Widget _downloadFeesReceiptDialog(List<int> paymentHistoryIds) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 8.0,
      backgroundColor: Colors.white,
      child: BlocConsumer<DownloadStudentFeeReceiptCubit,
          DownloadStudentFeeReceiptState>(
        listener: (context, state) {
          if (state is DownloadStudentFeeReceiptSuccess) {
            debugPrint('Opening PDF at: ${state.downloadedFilePath}');
            OpenFilex.open(state.downloadedFilePath).then((result) {
              debugPrint('OpenFilex result: ${result.type} - ${result.message}');
              if (result.type != ResultType.done) {
                Utils.showSnackBar(
                  message: "Gagal membuka file: ${result.message}",
                  context: context,
                );
              }
            });
            Get.back();
          }
        },
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header with icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.maroonPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: widget.maroonPrimary,
                    size: 32,
                  ),
                ).animate().fadeIn().scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                    ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Download Struk Pembayaran',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Memproses struk pembayaran siswa',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Loading indicator or status
                if (state is DownloadStudentFeeReceiptInProgress)
                  Column(
                    children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(
                          color: widget.maroonPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memproses dokumen...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else if (state is DownloadStudentFeeReceiptFailure)
                  Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<DownloadStudentFeeReceiptCubit>()
                              .downloadStudentFeeReceipt(
                                  paymentHistoryIds: paymentHistoryIds,
                                  studentName: widget.studentDetails.fullName ??
                                      "Student");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.maroonPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          Utils.getTranslatedLabel(retryKey),
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<DownloadStudentFeeReceiptCubit>()
                          .downloadStudentFeeReceipt(
                              paymentHistoryIds: paymentHistoryIds,
                              studentName:
                                  widget.studentDetails.fullName ?? "Student");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.maroonPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.download_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Download Sekarang',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                // Cancel button
                if (state is DownloadStudentFeeReceiptInProgress)
                  const SizedBox(height: 16)
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - label with icon
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: widget.maroonPrimary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: widget.maroonPrimary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ":",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),

          // Right side - value with better constraints
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? widget.maroonPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Build a payment history item
  Widget _buildPaymentHistoryItem(PaymentHistory payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and method
          Row(
            children: [
              // Date with icon
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.maroonPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: widget.maroonPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        payment.paymentDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Method with colored badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.maroonPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.paymentMethod,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.maroonPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Nominal",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                formatRupiah(payment.amount),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.maroonPrimary,
                ),
              ),
            ],
          ),

          // View proof image if available
          if (payment.proofImage != null && payment.proofImage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: () {
                  // Open image in dialog with improved UI
                  Get.dialog(
                    Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with gradient
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  widget.maroonPrimary,
                                  const Color(0xFF9A1E3C),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Bukti Pembayaran",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Close button as overlay
                          Stack(
                            children: [
                              // Image container
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(Get.context!).size.height *
                                          0.6,
                                  maxWidth:
                                      MediaQuery.of(Get.context!).size.width *
                                          0.8,
                                ),
                                // ClipRRect kept for rounded corners while
                                // InteractiveViewer enables pinch-zoom & pan
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(16),
                                  ),
                                  child: InteractiveViewer(
                                    panEnabled: true,
                                    scaleEnabled: true,
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    child: Image.network(
                                      payment.proofImage!,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return SizedBox(
                                          height: 300,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                              color: widget.maroonPrimary,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              SizedBox(
                                        height: 300,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.error_outline,
                                                  color: Colors.red, size: 48),
                                              const SizedBox(height: 16),
                                              Text(
                                                "Gagal memuat gambar",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Close button overlay
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => Get.back(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Lihat Bukti Pembayaran",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we have payment data in either the old or new format
    final bool hasFeeDetails = widget.studentDetails.paidFeeDetails != null;
    final bool hasPaymentStatus = widget.studentDetails.paymentStatus != null;

    // Get the payment history
    final List<PaymentHistory> paymentHistory =
        widget.studentDetails.paymentHistory ??
            widget.studentDetails.paidFeeDetails?.paymentHistory ??
            [];

    // Debug info
    debugPrint('=================== PAYMENT DETAILS DEBUG ===================');
    debugPrint('Student ID: ${widget.studentDetails.id}');
    debugPrint('Student Name: ${widget.studentDetails.fullName}');
    debugPrint('Has paymentStatus: $hasPaymentStatus');
    debugPrint(
        'Has direct payment_history: ${widget.studentDetails.paymentHistory != null}');
    debugPrint(
        'Has paidFeeDetails: ${widget.studentDetails.paidFeeDetails != null}');
    debugPrint(
        'Has paidFeeDetails.paymentHistory: ${widget.studentDetails.paidFeeDetails?.paymentHistory != null}');
    debugPrint('Total payment history items: ${paymentHistory.length}');
    if (paymentHistory.isNotEmpty) {
      debugPrint(
          'First payment: ${paymentHistory.first.amount} on ${paymentHistory.first.paymentDate}');
    }
    debugPrint('=========================================================');

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if (_animationController.isAnimating) {
              return;
            }

            if (_animationController.isCompleted) {
              _animationController.reverse();
            } else {
              _animationController.forward();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with student info
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Index number
                      SizedBox(
                        width: 30,
                        child: Text(
                          "${widget.index + 1}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                      // Student details
                      Expanded(
                        child: Row(
                          children: [
                            // Student avatar or icon
                            Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color:
                                    widget.maroonPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.studentDetails.fullName?.isNotEmpty ==
                                          true
                                      ? widget.studentDetails.fullName![0]
                                          .toUpperCase()
                                      : "S",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.maroonPrimary,
                                  ),
                                ),
                              ),
                            ),

                            // Name and class with proper constraints
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.studentDetails.fullName ?? "-",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    // Use class section from new API structure if available
                                    widget.studentDetails.classSection
                                            ?.fullName ??
                                        widget.studentDetails.student
                                            ?.classSection?.fullName ??
                                        widget.studentDetails.rollNumber ??
                                        "-",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Toggle indicator
                      Transform.rotate(
                        angle: (pi * _iconAngleAnimation.value) / 180,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: widget.maroonPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expanded details
                AnimatedOpacity(
                  opacity: _opacityAnimation.value,
                  duration: const Duration(milliseconds: 300),
                  child: _animationController.value > 0.5
                      ? Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section title
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(bottom: 12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.payments_rounded,
                                      size: 16,
                                      color: widget.maroonPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Detail Pembayaran',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: widget.maroonPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Fee details - prioritize new API format if available
                              _buildInfoRow(
                                label: Utils.getTranslatedLabel(totalFeeKey),
                                value: formatRupiah(hasPaymentStatus
                                    ? widget.studentDetails.paymentStatus!
                                        .totalAmount
                                    : (widget.compolsoryFeeAmount +
                                        widget.optionalFeeAmount)),
                                icon: Icons.monetization_on_outlined,
                              ),

                              _buildInfoRow(
                                label: 'ID Siswa',
                                value: '${widget.studentDetails.id ?? "N/A"}',
                                icon: Icons.person_pin,
                                valueColor: Colors.indigo[700],
                              ),

                              _buildInfoRow(
                                label: 'Jumlah Dibayar',
                                value: formatRupiah(hasPaymentStatus
                                    ? widget.studentDetails.paymentStatus!
                                        .paidAmount
                                    : (widget.studentDetails.paidFeeDetails
                                            ?.paidAmount ??
                                        0.0)),
                                icon: Icons.payments,
                                valueColor: Colors.green[700],
                              ),

                              if (hasPaymentStatus ||
                                  (hasFeeDetails &&
                                      widget.studentDetails.paidFeeDetails!
                                              .remainingAmount >
                                          0))
                                _buildInfoRow(
                                  label: 'Sisa Pembayaran',
                                  value: formatRupiah(hasPaymentStatus
                                      ? widget.studentDetails.paymentStatus!
                                          .remainingAmount
                                      : (widget.studentDetails.paidFeeDetails
                                              ?.remainingAmount ??
                                          0.0)),
                                  icon: widget.studentDetails.paymentStatus
                                                  ?.isFullyPaid ==
                                              true ||
                                          widget.studentDetails.paidFeeDetails
                                                  ?.isFullyPaid ==
                                              true
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  valueColor: widget.studentDetails
                                                  .paymentStatus?.isFullyPaid ==
                                              true ||
                                          widget.studentDetails.paidFeeDetails
                                                  ?.isFullyPaid ==
                                              true
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),

                              _buildInfoRow(
                                label: 'Status',
                                value: widget.studentDetails.paymentStatus
                                                ?.isFullyPaid ==
                                            true ||
                                        widget.studentDetails.paidFeeDetails
                                                ?.isFullyPaid ==
                                            true
                                    ? "Lunas"
                                    : "Belum Lunas",
                                icon: Icons.info_outline,
                                valueColor: widget.studentDetails.paymentStatus
                                                ?.isFullyPaid ==
                                            true ||
                                        widget.studentDetails.paidFeeDetails
                                                ?.isFullyPaid ==
                                            true
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),

                              if (paymentHistory.isNotEmpty) ...[
                                // Payment history section title with improved design
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(
                                      bottom: 12, top: 16),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: widget.maroonPrimary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.history_rounded,
                                          size: 16,
                                          color: widget.maroonPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Riwayat Pembayaran',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: widget.maroonPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      // Payment count badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: widget.maroonPrimary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${paymentHistory.length}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: widget.maroonPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Payment history list
                                ...paymentHistory.map((payment) =>
                                    _buildPaymentHistoryItem(payment)),
                              ],

                              // Payment receipt section with improved design
                              if (hasFeeDetails || hasPaymentStatus)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 16),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () =>
                                          _downloadFeeReceipt(), // This calls our updated method
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              widget.maroonPrimary,
                                              const Color(0xFF9A1E3C),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.maroonPrimary
                                                  .withValues(alpha: 0.3),
                                              offset: const Offset(0, 3),
                                              blurRadius: 6,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Animated icon
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.download_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Text
                                            Text(
                                              'Unduh Struk Pembayaran',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms, duration: 500.ms)
                                    .slideY(begin: 0.2, end: 0),
                            ],
                          ),
                        )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad)
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

