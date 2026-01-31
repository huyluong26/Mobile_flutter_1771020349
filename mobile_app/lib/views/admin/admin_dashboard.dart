import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Admin Dashboard Screen
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Quản Trị'),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: () => authViewModel.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin welcome section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${authViewModel.currentUser?.fullName ?? 'Admin'}!',
                          style: AppTypography.heading2.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ADMIN',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Quản lý hệ thống',
              style: AppTypography.heading2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),

            _buildMenuCard(
              context,
              icon: Icons.people,
              title: 'Quản lý thành viên',
              subtitle: 'Xem và quản lý danh sách thành viên',
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/admin/members'),
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Quản lý ví tiền',
              subtitle: 'Duyệt nạp tiền, xem giao dịch',
              color: Colors.amber,
              onTap: () => Navigator.pushNamed(context, '/admin/wallet'),
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              icon: Icons.calendar_today,
              title: 'Quản lý đặt sân',
              subtitle: 'Xem lịch và quản lý booking',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/admin/bookings'),
            ),
            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              icon: Icons.emoji_events,
              title: 'Quản lý giải đấu',
              subtitle: 'Tạo và quản lý giải đấu',
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/admin/tournaments'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
