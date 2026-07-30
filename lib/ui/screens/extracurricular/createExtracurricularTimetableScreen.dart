import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularTimetableEntry.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricular.dart';
import 'package:eschool_saas_staff/cubits/extracurricularTimetable/extracurricularTimetableCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';

class CreateExtracurricularTimetableScreen extends StatefulWidget {
  final ExtracurricularTimetableEntry? existingEntry;
  final List<Extracurricular>? extracurriculars;
  final String? selectedExtracurricularId;

  const CreateExtracurricularTimetableScreen({
    super.key,
    this.existingEntry,
    this.extracurriculars,
    this.selectedExtracurricularId,
  });

  @override
  State<CreateExtracurricularTimetableScreen> createState() =>
      _CreateExtracurricularTimetableScreenState();
}

class _CreateExtracurricularTimetableScreenState
    extends State<CreateExtracurricularTimetableScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  String? selectedExtracurricularId;
  String? selectedDay;
  bool get isEditMode => widget.existingEntry != null;

  Color get _primaryColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE53935)
      : const Color(0xffd22f3c);
  Color get _highlightColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFEF5350)
      : const Color(0xffd22f3c);
  final Color _accentColor = const Color(0xFFD4A574); // Warm gold
  final Color _softColor = const Color(0xFFF5E6D3); // Cream

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final Map<String, String> dayTranslations = {
    'Monday': 'Senin',
    'Tuesday': 'Selasa',
    'Wednesday': 'Rabu',
    'Thursday': 'Kamis',
    'Friday': 'Jumat',
    'Saturday': 'Sabtu',
    'Sunday': 'Minggu',
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (isEditMode) {
      final entry = widget.existingEntry!;
      selectedExtracurricularId = entry.extracurricularId;
      selectedDay = entry.day;
      _startTimeController.text = entry.startTime;
      _endTimeController.text = entry.endTime;
    } else {
      selectedExtracurricularId = widget.selectedExtracurricularId;
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomModernAppBar(
        title: isEditMode ? 'Edit Jadwal' : 'Tambah Jadwal',
        icon: isEditMode ? Icons.edit_calendar : Icons.add_alarm,
        fabAnimationController: AnimationController(vsync: this),
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocListener<ExtracurricularTimetableCubit,
          ExtracurricularTimetableState>(
        listener: (context, state) {
          if (state is ExtracurricularTimetableSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Get.back(result: true);
          } else if (state is ExtracurricularTimetableFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 30),
                _buildExtracurricularSection(),
                const SizedBox(height: 25),
                _buildDaySection(),
                const SizedBox(height: 25),
                _buildTimeSection(),
                const SizedBox(height: 40),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryColor.withValues(alpha: 0.1),
              _softColor.withValues(alpha: 0.3)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isEditMode ? Icons.edit_calendar : Icons.add_alarm,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditMode
                        ? 'Edit Jadwal Ekstrakurikuler'
                        : 'Tambah Jadwal Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEditMode
                        ? 'Perbarui informasi jadwal ekstrakurikuler'
                        : 'Atur waktu pelaksanaan ekstrakurikuler',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
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

  Widget _buildExtracurricularSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ekstrakurikuler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.extracurriculars != null &&
                widget.extracurriculars!.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: selectedExtracurricularId,
                decoration: InputDecoration(
                  labelText: 'Pilih Ekstrakurikuler',
                  prefixIcon: Icon(Icons.school, color: _primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                items: widget.extracurriculars!.map((extracurricular) {
                  return DropdownMenuItem<String>(
                    value: extracurricular.id.toString(),
                    child: Text(extracurricular.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedExtracurricularId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pilih ekstrakurikuler';
                  }
                  return null;
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Data ekstrakurikuler tidak tersedia',
                        style: TextStyle(color: Colors.orange.shade700),
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

  Widget _buildDaySection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hari',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days.map((day) {
                final isSelected = selectedDay == day;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDay = day;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryColor
                          : _accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? _primaryColor
                            : _accentColor.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      dayTranslations[day] ?? day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedDay == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Pilih hari pelaksanaan',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waktu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    controller: _startTimeController,
                    label: 'Waktu Mulai',
                    icon: Icons.access_time,
                    hint: 'HH:MM',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeField(
                    controller: _endTimeController,
                    label: 'Waktu Selesai',
                    icon: Icons.access_time_filled,
                    hint: 'HH:MM',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      onTap: () => _selectTime(controller),
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pilih waktu';
        }
        if (!ExtracurricularTimetableEntry.isValidTimeFormat(value)) {
          return 'Format waktu tidak valid';
        }
        return null;
      },
    );
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ExtracurricularTimetableCubit,
        ExtracurricularTimetableState>(
      builder: (context, state) {
        final isLoading = state is ExtracurricularTimetableLoading;

        return FadeInUp(
          duration: const Duration(milliseconds: 900),
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _highlightColor],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : _submitForm,
                borderRadius: BorderRadius.circular(15),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          isEditMode ? 'Perbarui Jadwal' : 'Simpan Jadwal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih hari pelaksanaan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedExtracurricularId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih ekstrakurikuler'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate time range
      final entry = ExtracurricularTimetableEntry(
        extracurricularId: selectedExtracurricularId!,
        day: selectedDay!,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
      );

      if (!entry.isValidTimeRange) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu selesai harus lebih besar dari waktu mulai'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (isEditMode) {
        context.read<ExtracurricularTimetableCubit>().updateTimetableEntry(
              widget.existingEntry!.id!,
              entry,
            );
      } else {
        context
            .read<ExtracurricularTimetableCubit>()
            .createTimetableEntry(entry);
      }
    }
  }
}
