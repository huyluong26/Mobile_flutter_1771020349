import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/booking_model.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({Key? key}) : super(key: key);

  @override
  State<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  List<Booking> _bookings = [];
  List<Court> _courts = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courts = await apiService.getCourts();
      final from = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final to = from.add(const Duration(days: 7));
      final bookings = await apiService.getCalendar(from, to);

      setState(() {
        _courts = courts;
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Quản lý đặt sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, style: AppTypography.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tuần từ ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                            style: AppTypography.bodyLarge,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _selectDate,
                            child: const Text('Đổi ngày'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Courts section
                    Text(
                      'Danh sách sân (${_courts.length})',
                      style: AppTypography.heading2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    ..._courts.map((court) => _buildCourtCard(court)),

                    const SizedBox(height: 24),

                    // Bookings section
                    Text(
                      'Lịch đặt sân (${_bookings.length})',
                      style: AppTypography.heading2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    if (_bookings.isEmpty)
                      const Center(
                        child: Text(
                          'Không có booking trong tuần này',
                          style: AppTypography.bodyMedium,
                        ),
                      )
                    else
                      ..._bookings.map((booking) => _buildBookingCard(booking)),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourtDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showCourtDialog([Court? court]) {
    final nameController = TextEditingController(text: court?.name);
    final descController = TextEditingController(text: court?.description);
    final priceController = TextEditingController(
      text: court?.pricePerHour.toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          court == null ? 'Thêm sân mới' : 'Cập nhật sân',
          style: AppTypography.heading2.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Tên sân',
                  placeholder: 'Ví dụ: Sân số 1',
                  icon: Icons.sports_tennis,
                  controller: nameController,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Vui lòng nhập tên sân' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Giá mỗi giờ',
                  placeholder: 'Ví dụ: 200000',
                  icon: Icons.money,
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Vui lòng nhập giá' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Mô tả',
                  placeholder: 'Ví dụ: Sân ngoài trời, mái che...',
                  icon: Icons.description,
                  controller: descController,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveCourt(
              court?.id ?? 0,
              nameController.text,
              descController.text,
              double.tryParse(priceController.text) ?? 0,
              formKey,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              court == null ? 'Thêm' : 'Lưu',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCourt(
    int id,
    String name,
    String desc,
    double price,
    GlobalKey<FormState> formKey,
  ) async {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(context); // Close dialog
    showLoadingDialog(context);

    try {
      final court = Court(
        id: id,
        name: name,
        description: desc,
        pricePerHour: price,
        isActive: true,
      );

      if (id == 0) {
        await apiService.createCourt(court);
      } else {
        await apiService.updateCourt(court);
      }

      hideLoadingDialog(context);
      await showSuccessDialog(
        context,
        message: id == 0 ? 'Thêm sân thành công' : 'Cập nhật sân thành công',
      );
      _loadData();
    } catch (e) {
      hideLoadingDialog(context);
      showErrorDialog(context, message: e.toString());
    }
  }

  Future<void> _deleteCourt(Court court) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Xóa sân',
      message:
          'Bạn có chắc chắn muốn xóa sân "${court.name}"? Thao tác này không thể hoàn tác.',
      confirmText: 'Xóa',
    );

    if (confirm) {
      showLoadingDialog(context);
      try {
        await apiService.deleteCourt(court.id);
        hideLoadingDialog(context);
        await showSuccessDialog(context, message: 'Đã xóa sân thành công');
        _loadData();
      } catch (e) {
        hideLoadingDialog(context);
        showErrorDialog(context, message: e.toString());
      }
    }
  }

  Widget _buildCourtCard(Court court) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_tennis, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  court.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (court.description != null)
                  Text(
                    court.description!,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,###', 'vi_VN').format(court.pricePerHour)} VND/h',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: AppColors.textMuted),
            onPressed: () => _showCourtDialog(court),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
            onPressed: () => _deleteCourt(court),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.courtName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.statusDisplay,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _getStatusColor(booking.status),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(booking.dateDisplay, style: AppTypography.bodyMedium),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(booking.timeDisplay, style: AppTypography.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(booking.memberName, style: AppTypography.bodyMedium),
              const Spacer(),
              Text(
                '${NumberFormat('#,###', 'vi_VN').format(booking.totalPrice)} VND',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return AppColors.textMuted;
    }
  }
}
