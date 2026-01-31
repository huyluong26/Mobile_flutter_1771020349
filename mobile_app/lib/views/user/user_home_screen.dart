import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/api_service.dart';
import '../../models/tournament_model.dart';
import 'widgets/user_home_widgets.dart';
// Note: We don't necessarily need screen imports here if we switch tabs,
// but keeping them doesn't hurt.
import 'booking_calendar_screen.dart';
import 'tournament_list_screen.dart';
import 'wallet_screen.dart';

class UserHomeScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;

  const UserHomeScreen({Key? key, this.onSwitchTab}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Tournament> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final data = await apiService.getTournaments();
      if (mounted) {
        setState(() {
          _tournaments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthViewModel>(context).currentUser;
    const Color kBackgroundColor = Color(0xFF112117);
    const Color kPrimaryColor = Color(0xFF2EEA79);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          HomeSliverAppBar(
            user: user,
            onNotificationTap: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  HomeWalletCard(
                    balance: user?.walletBalance ?? 0,
                    onDepositTap: () {
                      // Switch to Wallet Tab (Index 3)
                      if (widget.onSwitchTab != null) {
                        widget.onSwitchTab!(3);
                      } else {
                        // Fallback purely for safety
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WalletScreen(),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  HomeActionCards(
                    onBookingTap: () {
                      // Switch to Booking Tab (Index 1)
                      if (widget.onSwitchTab != null) {
                        widget.onSwitchTab!(1);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingCalendarScreen(),
                          ),
                        );
                      }
                    },
                    onTournamentTap: () {
                      // Switch to Tournament Tab (Index 2)
                      if (widget.onSwitchTab != null) {
                        widget.onSwitchTab!(2);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TournamentListScreen(),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  HomeStatsRow(tier: user?.tier ?? "Standard"),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Giải đấu gần đây",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.onSwitchTab != null) {
                            widget.onSwitchTab!(2);
                          }
                        },
                        child: const Text(
                          "Tất cả",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildTournamentList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Color(0xFF2EEA79)),
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Chưa có giải đấu nào",
            style: TextStyle(color: Color(0xFF9DB8A8)),
          ),
        ),
      );
    }

    return Column(
      children: _tournaments
          .map(
            (t) => TournamentListItem(
              tournament: t,
              onTap: () {
                // Detail screen still needs push
                // Navigator.pushNamed(context, '/tournament_detail', arguments: t);
              },
            ),
          )
          .toList(),
    );
  }
}
