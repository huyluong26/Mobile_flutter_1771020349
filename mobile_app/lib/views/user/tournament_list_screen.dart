import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/tournament_model.dart';
import '../../widgets/app_dialogs.dart';

/// Tournament list screen for users
class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({Key? key}) : super(key: key);

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Tournament> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    setState(() => _isLoading = true);
    try {
      final tournaments = await apiService.getTournaments();
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Tournament> _filterByStatus(String tab) {
    if (tab == 'All') return _tournaments;
    return _tournaments.where((t) {
      if (tab == 'Upcoming') {
        return t.status == 'Upcoming' ||
            t.status == 'Registering' ||
            t.status == 'Open';
      }
      if (tab == 'Ongoing') {
        return t.status == 'Ongoing' || t.status == 'DrawCompleted';
      }
      if (tab == 'Completed') {
        return t.status == 'Completed' || t.status == 'Finished';
      }
      return t.status == tab;
    }).toList();
  }

  Future<void> _joinTournament(Tournament tournament) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Tham gia giải đấu',
      message:
          'Phí tham gia: ${NumberFormat('#,###', 'vi_VN').format(tournament.entryFee)} VND\n\nBạn có chắc muốn tham gia?',
    );

    if (confirm) {
      try {
        await apiService.joinTournament(tournament.id, '');
        if (mounted) {
          context.read<AuthViewModel>().refreshProfile();
        }
        await showSuccessDialog(
          context,
          message: 'Đã đăng ký tham gia thành công!',
        );
        _loadTournaments();
      } catch (e) {
        await showErrorDialog(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Giải đấu'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Đang mở'),
            Tab(text: 'Đang diễn ra'),
            Tab(text: 'Đã kết thúc'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentList(_filterByStatus('Upcoming')),
                _buildTournamentList(_filterByStatus('Ongoing')),
                _buildTournamentList(_filterByStatus('Completed')),
              ],
            ),
    );
  }

  Widget _buildTournamentList(List<Tournament> tournaments) {
    if (tournaments.isEmpty) {
      return const Center(
        child: Text('Không có giải đấu', style: AppTypography.bodyMedium),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournaments,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tournaments.length,
        itemBuilder: (context, index) =>
            _buildTournamentCard(tournaments[index]),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final canJoin =
        tournament.status == 'Upcoming' || tournament.status == 'Registering';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 40,
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
                _buildStatusBadge(tournament),
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
                  'Ngày thi đấu',
                  tournament.dateDisplay,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.people,
                  'Số đội',
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
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: View bracket/standings
                    },
                    child: const Text('Xem chi tiết'),
                  ),
                ),
                if (canJoin) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: tournament.isJoined
                          ? null
                          : () => _joinTournament(tournament),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tournament.isJoined
                            ? Colors.grey
                            : AppColors.primary,
                      ),
                      child: Text(
                        tournament.isJoined ? 'Đã tham gia' : 'Tham gia',
                        style: TextStyle(
                          color: tournament.isJoined
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildStatusBadge(Tournament tournament) {
    Color color;
    switch (tournament.status) {
      case 'Upcoming':
      case 'Registering':
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
