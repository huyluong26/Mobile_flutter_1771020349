import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/api_service.dart';
import '../../models/auth_models.dart';

/// Profile screen for users
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  String? _getValidAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    // Remove leading slash if present to avoid double slashes if baseUrl ends with slash
    // But ApiService.baseUrl usually doesn't have trailing slash.
    // However, backend returns "/uploads/...", so we just concat.
    // Need ApiService import.
    // Actually, let's use ApiService.baseUrl directly.
    final fullUrl = '${ApiService.baseUrl.replaceAll("/api", "")}$url';
    print('🖼️ Avatar URL: $fullUrl (original: $url)');
    return fullUrl;
  }

  void _showEditProfileDialog(BuildContext context, UserProfile user) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final TextEditingController nameController = TextEditingController(
      text: user.fullName,
    );
    File? tempImage;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: const Text(
                "Chỉnh sửa hồ sơ",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final XFile? pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          setStateDialog(() {
                            tempImage = File(pickedFile.path);
                          });
                        }
                      } catch (e) {
                        print("Picker Error: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi chọn ảnh: $e")),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.backgroundDark,
                          backgroundImage: tempImage != null
                              ? FileImage(tempImage!) as ImageProvider
                              : (user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty)
                              ? NetworkImage(
                                  _getValidAvatarUrl(user.avatarUrl)!,
                                )
                              : null,
                          child:
                              (tempImage == null &&
                                  (user.avatarUrl == null ||
                                      user.avatarUrl!.isEmpty))
                              ? Text(
                                  user.fullName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Họ và tên",
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.borderDark),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : () async {
                          setStateDialog(() => _isUploading = true);

                          bool success = await authViewModel.updateUserInfo(
                            fullName: nameController.text,
                            imageFile: tempImage,
                          );

                          setStateDialog(() => _isUploading = false);

                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Cập nhật thành công"),
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  authViewModel.errorMessage ?? "Lỗi cập nhật",
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Lưu",
                          style: TextStyle(color: Colors.black),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text('Cá nhân'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () => _showEditProfileDialog(context, user),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary,
                                backgroundImage:
                                    (user.avatarUrl != null &&
                                        user.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(
                                        _getValidAvatarUrl(user.avatarUrl)!,
                                      )
                                    : null,
                                child:
                                    (user.avatarUrl == null ||
                                        user.avatarUrl!.isEmpty)
                                    ? Text(
                                        user.fullName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: AppTypography.heading2.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(user.email ?? '', style: AppTypography.bodyMedium),
                        const SizedBox(height: 16),

                        // Rank & Tier
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              icon: Icons.star,
                              label: 'Rank',
                              value: '2.5',
                              color: AppColors.primary,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.borderDark,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),
                            _buildStatItem(
                              icon: Icons.military_tech,
                              label: 'Tier',
                              value: user.tier ?? 'Standard',
                              color: Colors.amber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu items
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Chỉnh sửa hồ sơ',
                    onTap: () => _showEditProfileDialog(context, user),
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Lịch sử đặt sân',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.emoji_events_outlined,
                    title: 'Giải đấu đã tham gia',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    title: 'Danh sách thành viên',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/admin/members',
                    ), // Or public list
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Trợ giúp & Hỗ trợ',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => authViewModel.logout(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textMuted),
        title: Text(title, style: AppTypography.bodyLarge),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
