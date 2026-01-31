import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/hero_header.dart';
import '../widgets/app_dialogs.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.register(
        _usernameController.text.trim(),
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          showSuccessDialog(
            context,
            title: 'Đăng ký thành công',
            message: 'Chào mừng bạn đến với PicklePro!',
            onClose: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (route) => false);
            },
          );
        } else {
          showErrorDialog(
            context,
            title: 'Đăng ký thất bại',
            message:
                authViewModel.errorMessage ??
                'Vui lòng kiểm tra thông tin và thử lại',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HeroHeader(
                title: 'PicklePro',
                subtitle: 'Tham gia cộng đồng Pickleball!',
                minHeight: 220,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đăng Ký', style: AppTypography.heading2),
                      const SizedBox(height: 8),
                      Text(
                        'Tạo tài khoản để bắt đầu hành trình Pickleball của bạn.',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      AppTextField(
                        label: 'Họ và tên',
                        placeholder: 'Nhập họ và tên đầy đủ',
                        icon: Icons.badge_outlined,
                        controller: _fullNameController,
                        validator: (v) => v?.isEmpty ?? true
                            ? 'Vui lòng nhập họ và tên'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Tên đăng nhập',
                        placeholder: 'Nhập tên đăng nhập',
                        icon: Icons.person_outline,
                        controller: _usernameController,
                        validator: (v) {
                          if (v?.isEmpty ?? true)
                            return 'Vui lòng nhập tên đăng nhập';
                          if (v!.length < 3)
                            return 'Tên đăng nhập phải có ít nhất 3 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Email',
                        placeholder: 'Nhập địa chỉ email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Vui lòng nhập email';
                          if (!v!.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppPasswordField(
                        label: 'Mật khẩu',
                        placeholder: 'Tạo mật khẩu mạnh',
                        controller: _passwordController,
                        validator: (v) {
                          if (v?.isEmpty ?? true)
                            return 'Vui lòng nhập mật khẩu';
                          if (v!.length < 6)
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AppPasswordField(
                        label: 'Xác nhận mật khẩu',
                        placeholder: 'Nhập lại mật khẩu',
                        controller: _confirmPasswordController,
                        validator: (v) {
                          if (v?.isEmpty ?? true)
                            return 'Vui lòng xác nhận mật khẩu';
                          if (v != _passwordController.text)
                            return 'Mật khẩu không khớp';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      AppPrimaryButton(
                        text: 'Đăng Ký',
                        isLoading: _isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 32),

                      const DividerWithText(text: 'HOẶC ĐĂNG KÝ BẰNG'),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          AppSocialButton(
                            text: 'Google',
                            icon: const GoogleIcon(),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 16),
                          AppSocialButton(
                            text: 'Apple',
                            icon: const AppleIcon(),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Đã có tài khoản?',
                              style: AppTypography.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Đăng nhập',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
