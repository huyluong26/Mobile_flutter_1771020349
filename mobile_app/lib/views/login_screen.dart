import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/hero_header.dart';
import '../widgets/app_dialogs.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final authViewModel = context.read<AuthViewModel>();
      final success = await authViewModel.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (!success && mounted) {
        showErrorDialog(
          context,
          title: 'Đăng nhập thất bại',
          message:
              authViewModel.errorMessage ??
              'Vui lòng kiểm tra thông tin và thử lại',
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Đăng Nhập',
                  style: AppTypography.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập thông tin đăng nhập của bạn để tiếp tục.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Username Field
                AppTextField(
                  label: 'Tên đăng nhập',
                  placeholder: 'Nhập tên đăng nhập',
                  icon: Icons.person_outline,
                  controller: _usernameController,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Vui lòng nhập tên đăng nhập'
                      : null,
                ),
                const SizedBox(height: 20),

                // Password Field
                AppPasswordField(
                  label: 'Mật khẩu',
                  placeholder: 'Nhập mật khẩu',
                  controller: _passwordController,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Vui lòng nhập mật khẩu'
                      : null,
                ),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: Text(
                      'Quên mật khẩu?',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                AppPrimaryButton(
                  text: 'Đăng Nhập',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),
                
                const SizedBox(height: 40),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản?',
                      style: AppTypography.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: Text(
                        'Đăng ký ngay',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
