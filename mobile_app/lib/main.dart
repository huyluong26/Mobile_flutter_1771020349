import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/member_viewmodel.dart';
import 'views/login_screen.dart';
import 'views/register_screen.dart';
import 'views/user/main_layout.dart';
import 'views/user/notifications_screen.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/admin/member_list_screen.dart';
import 'views/admin/wallet_management_screen.dart';
import 'views/admin/booking_management_screen.dart';
import 'views/admin/tournament_management_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => MemberViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PicklePro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainLayout(),
        '/notifications': (context) => const NotificationsScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/admin/members': (context) => const MemberListScreen(),
        '/admin/wallet': (context) => const WalletManagementScreen(),
        '/admin/bookings': (context) => const BookingManagementScreen(),
        '/admin/tournaments': (context) => const TournamentManagementScreen(),
      },
    );
  }
}

/// Auth wrapper - routes based on role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        if (authViewModel.isAuthenticated) {
          final role = authViewModel.currentUser?.role;
          if (role == 'Admin') {
            return const AdminDashboard();
          } else {
            return const MainLayout();
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
