import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/tournament_model.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({Key? key}) : super(key: key);

  @override
  State<TournamentManagementScreen> createState() =>
      _TournamentManagementScreenState();
}

class _TournamentManagementScreenState
    extends State<TournamentManagementScreen> {
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await apiService.getTournaments();
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final entryFeeController = TextEditingController(text: '0');
    final prizePoolController = TextEditingController(text: '0');
    DateTime startDate = DateTime.now().add(const Duration(days: 7));
    DateTime endDate = DateTime.now().add(const Duration(days: 14));
    String format = 'Knockout';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'Tạo giải đấu mới',
            style: AppTypography.heading2.copyWith(fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(labelText: 'Tên giải đấu'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: entryFeeController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Phí tham gia',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: prizePoolController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Giải thưởng',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: format,
                  decoration: const InputDecoration(labelText: 'Thể thức'),
                  dropdownColor: AppColors.surfaceDark,
                  items: const [
                    DropdownMenuItem(
                      value: 'Knockout',
                      child: Text('Loại trực tiếp'),
                    ),
                    DropdownMenuItem(
                      value: 'RoundRobin',
                      child: Text('Vòng tròn'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => format = v!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null)
                      setDialogState(() => startDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày kết thúc'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  showErrorDialog(
                    context,
                    message: 'Vui lòng nhập tên giải đấu',
                  );
                  return;
                }
                try {
                  await apiService.createTournament(
                    name: nameController.text.trim(),
                    startDate: startDate,
                    endDate: endDate,
                    format: format,
                    entryFee: double.tryParse(entryFeeController.text) ?? 0,
                    prizePool: double.tryParse(prizePoolController.text) ?? 0,
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  showErrorDialog(
                    context,
                    message: e.toString().replaceAll('Exception: ', ''),
                  );
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      showSuccessDialog(context, message: 'Đã tạo giải đấu thành công');
      _loadTournaments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Quản lý giải đấu'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
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
                    onPressed: _loadTournaments,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTournaments,
              color: AppColors.primary,
              child: _tournaments.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có giải đấu nào',
                        style: AppTypography.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tournaments.length,
                      itemBuilder: (context, index) =>
                          _buildTournamentCard(_tournaments[index]),
                    ),
            ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tournament.formatDisplay,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(tournament.status),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_today,
                  'Ngày bắt đầu',
                  tournament.dateDisplay,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.people,
                  'Số đội tham gia',
                  '${tournament.participantCount}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.attach_money,
                  'Phí tham gia',
                  '${NumberFormat('#,###', 'vi_VN').format(tournament.entryFee)} VND',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.emoji_events,
                  'Giải thưởng',
                  '${NumberFormat('#,###', 'vi_VN').format(tournament.prizePool)} VND',
                ),
              ],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Delete button
                IconButton(
                  onPressed: () async {
                    final confirm = await showConfirmDialog(
                      context,
                      title: 'Xóa giải đấu',
                      message:
                          'Bạn có chắc muốn xóa giải đấu "${tournament.name}"?',
                    );
                    if (confirm) {
                      try {
                        await apiService.deleteTournament(tournament.id);
                        showSuccessDialog(context, message: 'Đã xóa giải đấu');
                        _loadTournaments();
                      } catch (e) {
                        showErrorDialog(
                          context,
                          message: e.toString().replaceAll('Exception: ', ''),
                        );
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  tooltip: 'Xóa',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await apiService.generateSchedule(tournament.id);
                        showSuccessDialog(
                          context,
                          message: 'Đã tạo lịch thi đấu',
                        );
                      } catch (e) {
                        showErrorDialog(
                          context,
                          message: e.toString().replaceAll('Exception: ', ''),
                        );
                      }
                    },
                    child: const Text('Tạo lịch'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: View tournament details
                    },
                    child: const Text('Chi tiết'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTypography.bodyMedium),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Upcoming':
        color = Colors.blue;
        break;
      case 'Ongoing':
        color = Colors.orange;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      default:
        color = AppColors.textMuted;
    }

    final tournament = Tournament(
      id: 0,
      name: '',
      startDate: DateTime.now(),
      status: status,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tournament.statusDisplay,
        style: AppTypography.bodyMedium.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
