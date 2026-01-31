import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../models/member_model.dart';
import '../../widgets/app_text_field.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({Key? key}) : super(key: key);

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load members when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberViewModel>().loadMembers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<MemberViewModel>().loadMembers(
      search: _searchController.text.trim(),
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Quản lý thành viên'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm thành viên...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch();
                        },
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search, color: AppColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Member list
          Expanded(
            child: Consumer<MemberViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading && viewModel.members.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (viewModel.state == MemberListState.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.errorMessage ?? 'Có lỗi xảy ra',
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => viewModel.refresh(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có thành viên nào',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.refresh(),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        viewModel.members.length + 1, // +1 for pagination
                    itemBuilder: (context, index) {
                      if (index == viewModel.members.length) {
                        // Pagination controls
                        return _buildPaginationControls(viewModel);
                      }
                      return _buildMemberCard(viewModel.members[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          backgroundImage: member.avatarUrl != null
              ? NetworkImage(member.avatarUrl!)
              : null,
          child: member.avatarUrl == null
              ? Text(
                  member.fullName.isNotEmpty
                      ? member.fullName[0].toUpperCase()
                      : '?',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.fullName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildTierBadge(member.tier),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(member.email, style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  Icons.star,
                  'Rank: ${member.rankLevel.toStringAsFixed(1)}',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.account_balance_wallet,
                  '${member.walletBalance.toStringAsFixed(0)} VND',
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: member.isActive ? AppColors.success : AppColors.error,
          ),
        ),
        onTap: () {
          // TODO: Navigate to member detail
        },
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    Color color;
    switch (tier) {
      case 'Gold':
        color = Colors.amber;
        break;
      case 'Platinum':
        color = Colors.blueGrey;
        break;
      default:
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tier,
        style: AppTypography.bodyMedium.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(MemberViewModel viewModel) {
    if (viewModel.totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: viewModel.currentPage > 1
                ? () => viewModel.previousPage()
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
            disabledColor: AppColors.textMuted,
          ),
          const SizedBox(width: 16),
          Text(
            'Trang ${viewModel.currentPage} / ${viewModel.totalPages}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: viewModel.currentPage < viewModel.totalPages
                ? () => viewModel.nextPage()
                : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.primary,
            disabledColor: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
