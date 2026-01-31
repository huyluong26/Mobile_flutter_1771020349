import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/booking_model.dart';
import '../../widgets/app_dialogs.dart';

/// Booking Calendar Screen (Redesigned)
class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({Key? key}) : super(key: key);

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  List<Court> _courts = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;

  // For horizontal calendar
  final ScrollController _dateScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final courts = await apiService.getCourts();
      // Load 30 days around selected day
      final from = DateTime(_selectedDay.year, _selectedDay.month, 1);
      final to = from.add(const Duration(days: 60)); 
      final bookings = await apiService.getCalendar(from, to);
      setState(() {
        _courts = courts;
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorDialog(context, message: 'Không thể tải dữ liệu: $e');
      }
    }
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    return _bookings.where((b) {
      return b.startTime.year == day.year &&
          b.startTime.month == day.month &&
          b.startTime.day == day.day;
    }).toList();
  }

  String _getCancelFeeInfo(Booking booking) {
    // Logic: Trước 24h hoàn 100%, sau đó hoàn 75%
    // Hiện tại hardcode theo logic cũ
    final refund = booking.totalPrice * 0.75;
    return 'Hoàn ${NumberFormat('#,###', 'vi_VN').format(refund)} VND (25% phí hủy)';
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Hủy đặt sân',
      message: 'Bạn có chắc muốn hủy booking này?\n'
          '${booking.courtName} - ${booking.timeDisplay}\n\n'
          '${_getCancelFeeInfo(booking)}',
    );

    if (!confirm) return;

    try {
      await apiService.cancelBooking(booking.id);
      if (mounted) {
        context.read<AuthViewModel>().refreshProfile();
        await showSuccessDialog(context, message: 'Đã hủy thành công!');
        _loadData();
      }
    } catch (e) {
      await showErrorDialog(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayBookings = _getBookingsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppColors.backgroundDark,
            title: const Text('Đặt Sân Pickleball', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: false,
            floating: true,
            pinned: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3,
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sports_tennis), SizedBox(width: 8), Text("Đặt sân")])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history), SizedBox(width: 8), Text("Lịch sử")])),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Booking Flow
            _buildBookingTab(dayBookings),
            
            // Tab 2: My Bookings
            _buildMyBookingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTab(List<Booking> dayBookings) {
    return Column(
      children: [
        // 1. Modern Date Picker
        _buildHorizontalDatePicker(),

        const SizedBox(height: 10),

        // 2. Summary Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, d MMM', 'vi').format(_selectedDay).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70, 
                  fontWeight: FontWeight.w600, 
                  letterSpacing: 1
                ),
              ),
              Text(
                "${_courts.length} sân sẵn sàng",
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. Court List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _courts.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _courts.length,
                    itemBuilder: (context, index) {
                      return _buildModernCourtCard(_courts[index], dayBookings);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.sports_tennis, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text("Chưa có sân nào trong hệ thống", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker() {
    // Generate dates: today + 14 days
    final List<DateTime> dates = List.generate(
      14,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    return Container(
      height: 90,
      color: AppColors.surfaceDark,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = isSameDay(date, _selectedDay);
          final isToday = isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = date;
                // Reload data if changing months involves fetching new data (simplified here)
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary 
                      : (isToday ? Colors.white38 : Colors.transparent),
                  width: 1.5
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'vi').format(date).toUpperCase(), // T2, T3...
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernCourtCard(Court court, List<Booking> dayBookings) {
     final authViewModel = context.read<AuthViewModel>();
     final myId = authViewModel.currentUser?.id;

    // Filter bookings for this court
    final courtBookings = dayBookings
        .where((b) => b.courtId == court.id && b.status != 'Cancelled')
        .toList();

    // Calculate availability stats
    int totalSlots = 15; // 7h-22h
    int bookedSlots = courtBookings.length;
    int availableSlots = totalSlots - bookedSlots;
    double progress = bookedSlots / totalSlots;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0,4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with visual
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
             ),
             padding: const EdgeInsets.all(16),
             child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Container(
                   padding: const EdgeInsets.all(10),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(12)
                   ),
                   child: const Icon(Icons.sports_tennis, color: Colors.white, size: 32),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         court.name,
                         style: const TextStyle(
                           color: Colors.white, 
                           fontSize: 18, 
                           fontWeight: FontWeight.bold
                         ),
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           Icon(Icons.access_time, size: 14, color: AppColors.primary),
                           const SizedBox(width: 4),
                           const Text("07:00 - 22:00", style: TextStyle(color: Colors.white70, fontSize: 12)),
                           const SizedBox(width: 12),
                           Icon(Icons.bolt, size: 14, color: Colors.amber),
                           const SizedBox(width: 4),
                           Text("$availableSlots slots trống", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                         ],
                       )
                     ],
                   ),
                 ),
                 Column(
                   children: [
                     Text(
                        NumberFormat('#,###', 'vi_VN').format(court.pricePerHour),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)
                     ),
                     const Text("VND/h", style: TextStyle(color: Colors.white54, fontSize: 10)),
                   ],
                 )
               ],
             ),
          ),

          // 2. Timeline Visualization
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tình trạng sân", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double slotWidth = constraints.maxWidth / 15;
                    return Row(
                      children: List.generate(15, (index) {
                        final hour = 7 + index;
                        final booking = courtBookings.firstWhere(
                          (b) => b.startTime.hour <= hour && b.endTime.hour > hour,
                          orElse: () => Booking(id: -1, courtId: -1, courtName: '', memberId: 0, memberName: '', startTime: DateTime.now(), endTime: DateTime.now(), totalPrice: 0, status: 'Fake'),
                        );
                        final isBooked = booking.id != -1;
                        final isMy = isBooked && booking.memberId == myId;

                        Color color = const Color(0xFF333333);
                        if (isMy) color = Colors.blue;
                        else if (isBooked) color = Colors.red.withOpacity(0.6);
                        
                        return Container(
                          width: slotWidth - 2,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4)
                          ),
                        );
                      }),
                    );
                  }
                ),
              ],
            ),
          ),

          // 3. Time Slots Grid (Toggle visually)
          ExpansionTile(
            title: const Text("Chọn khung giờ", style: TextStyle(color: Colors.white, fontSize: 14)),
            iconColor: AppColors.primary,
            collapsedIconColor: Colors.white54,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
               Padding(
                 padding: const EdgeInsets.all(16),
                 child: Wrap(
                   spacing: 12,
                   runSpacing: 12,
                   children: List.generate(15, (index) {
                     final hour = 7 + index;
                     final slotTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour);
                     
                     // Check booking
                     final matching = courtBookings.where((b) => b.startTime.hour <= hour && b.endTime.hour > hour).toList();
                     final booking = matching.isNotEmpty ? matching.first : null;
                     
                     final isBooked = booking != null;
                     final isMy = booking?.memberId == myId;
                     final isPast = slotTime.isBefore(DateTime.now());

                     return _buildModernTimeSlot(
                       hour: hour, 
                       court: court, 
                       isBooked: isBooked, 
                       isMy: isMy, 
                       isPast: isPast,
                       booking: booking
                     );
                   }),
                 ),
               )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModernTimeSlot({
    required int hour, 
    required Court court, 
    required bool isBooked, 
    required bool isMy, 
    required bool isPast,
    Booking? booking
  }) {
    Color bg = const Color(0xFF2A2A2A);
    Color border = Colors.transparent;
    Color text = Colors.white70;
    bool canTap = false;

    if (isPast) {
      bg = Colors.black26;
      text = Colors.white24;
    } else if (isMy) {
      bg = Colors.blue.withOpacity(0.2);
      border = Colors.blue;
      text = Colors.blue;
      canTap = true;
    } else if (isBooked) {
      bg = Colors.red.withOpacity(0.1);
      // text = Colors.red;
      text = Colors.white24; // Dim text relative to available
    } else {
      bg = AppColors.primary.withOpacity(0.1);
      border = AppColors.primary.withOpacity(0.5);
      text = AppColors.primary;
      canTap = true;
    }

    return GestureDetector(
      onTap: canTap ? () {
        if (isMy && booking != null) {
          _cancelBooking(booking);
        } else if (!isBooked && !isPast) {
          _showQuickBookingDialog(court, hour);
        }
      } : null,
      child: Container(
        width: 70,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          "${hour}:00",
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showQuickBookingDialog(Court court, int hour) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.bookmark_add, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Xác nhận đặt sân', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _infoRow("Sân", court.name),
                  const Divider(color: Colors.white24),
                  _infoRow("Ngày", DateFormat('dd/MM/yyyy').format(_selectedDay)),
                   const Divider(color: Colors.white24),
                  _infoRow("Giờ", "${hour}:00 - ${hour+1}:00"),
                   const Divider(color: Colors.white24),
                  _infoRow("Giá", "${NumberFormat('#,###').format(court.pricePerHour)} đ", isPrice: true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createQuickBooking(court, hour);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
            ),
            child: const Text('Thanh toán & Đặt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: TextStyle(
            color: isPrice ? AppColors.primary : Colors.white, 
            fontWeight: isPrice ? FontWeight.bold : FontWeight.w500,
            fontSize: isPrice ? 16 : 14
          )),
        ],
      ),
    );
  }

  Future<void> _createQuickBooking(Court court, int hour) async {
    try {
      final startTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        hour,
      );
      await apiService.createBooking(court.id, startTime, 60);
      if (mounted) {
        context.read<AuthViewModel>().refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Row(children: const [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text("Đặt sân thành công!")]),
             backgroundColor: Colors.green,
             behavior: SnackBarBehavior.floating,
           )
        );
        _loadData();
      }
    } catch (e) {
      // Simplification of error handling
      showErrorDialog(context, message: e.toString());
    }
  }

  // --- Reuse existing My Bookings Tab Logic (visual updated) ---
  Widget _buildMyBookingsTab() {
    final authViewModel = context.read<AuthViewModel>();
    final myId = authViewModel.currentUser?.id;
    final myBookings = _bookings.where((b) => b.memberId == myId).toList();
    
    // Sort logic...
    final now = DateTime.now();
    myBookings.sort((a, b) {
      final aIsCancelled = a.status == 'Cancelled';
      final bIsCancelled = b.status == 'Cancelled';
      // ... same sort logic ...
      if (aIsCancelled && !bIsCancelled) return 1;
      if (!aIsCancelled && bIsCancelled) return -1;
      return b.startTime.compareTo(a.startTime);
    });

    if (myBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('Chưa có lịch sử đặt sân', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myBookings.length,
      itemBuilder: (context, index) {
        final booking = myBookings[index];
        final isCancelled = booking.status == 'Cancelled';
        final isFuture = booking.startTime.isAfter(DateTime.now());
        
        Color statusColor = isCancelled ? Colors.red : (isFuture ? AppColors.primary : Colors.grey);
        String statusText = isCancelled ? "Đã hủy" : (isFuture ? "Sắp diễn ra" : "Hoàn thành");

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: statusColor, width: 4))
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(booking.courtName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd/MM/yyyy').format(booking.startTime), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.white54),
                  const SizedBox(width: 8),
                  Text("${booking.startTime.hour}:00 - ${booking.endTime.hour}:00", style: const TextStyle(color: Colors.white70)),
                ],
              ),
              if (isFuture && !isCancelled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(booking),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.withOpacity(0.5))),
                    child: const Text("Hủy đặt sân", style: TextStyle(color: Colors.red)),
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }
}

/// Booking form bottom sheet
class BookingFormSheet extends StatefulWidget {
  final List<Court> courts;
  final DateTime selectedDate;
  final VoidCallback onBookingCreated;

  const BookingFormSheet({
    Key? key,
    required this.courts,
    required this.selectedDate,
    required this.onBookingCreated,
  }) : super(key: key);

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  Court? _selectedCourt;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _duration = 60;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.courts.isNotEmpty) {
      _selectedCourt = widget.courts.first;
    }
  }

  Future<void> _createBooking() async {
    if (_selectedCourt == null) {
      showErrorDialog(context, message: 'Vui lòng chọn sân');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await apiService.createBooking(_selectedCourt!.id, startTime, _duration);
      if (mounted) {
        context.read<AuthViewModel>().refreshProfile();
      }
      await showSuccessDialog(context, message: 'Đặt sân thành công!');
      widget.onBookingCreated();
    } catch (e) {
      await showErrorDialog(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Đặt sân', style: AppTypography.heading2.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(widget.selectedDate),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Court selector
          Text('Chọn sân', style: AppTypography.bodyLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<Court>(
            value: _selectedCourt,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            dropdownColor: AppColors.surfaceDark,
            items: widget.courts
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      '${c.name} - ${NumberFormat('#,###', 'vi_VN').format(c.pricePerHour)} VND/h',
                    ),
                  ),
                )
                .toList(),
            onChanged: (c) => setState(() => _selectedCourt = c),
          ),
          const SizedBox(height: 16),

          // Time selector
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giờ bắt đầu', style: AppTypography.bodyLarge),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime.format(context),
                              style: AppTypography.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thời lượng', style: AppTypography.bodyLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _duration,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      dropdownColor: AppColors.surfaceDark,
                      items: const [
                        DropdownMenuItem(value: 60, child: Text('1 giờ')),
                        DropdownMenuItem(value: 90, child: Text('1.5 giờ')),
                        DropdownMenuItem(value: 120, child: Text('2 giờ')),
                      ],
                      onChanged: (d) => setState(() => _duration = d ?? 60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Xác nhận đặt sân',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
