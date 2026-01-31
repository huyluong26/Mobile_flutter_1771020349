import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

/// User Home Screen (for regular members)
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Trang Chủ'),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: () => authViewModel.logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_tennis,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Chào mừng, ${authViewModel.currentUser?.fullName ?? 'User'}!',
              style: AppTypography.heading2,
            ),
            const SizedBox(height: 10),
            Text(
              'Ví: ${authViewModel.currentUser?.walletBalance.toStringAsFixed(0) ?? '0'} VND',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
