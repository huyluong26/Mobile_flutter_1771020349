import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/tournament_model.dart';
import '../../../models/auth_models.dart';

// Theme Constants
const Color kPrimaryColor = Color(0xFF2EEA79);
const Color kBackgroundColor = Color(0xFF112117);
const Color kCardBgColor = Color(
  0xFF161F1A,
); // Slightly lighter for transparency effect
const Color kTextSecondary = Color(0xFF9DB8A8);
const String kDefaultAvatar =
    "https://lh3.googleusercontent.com/aida-public/AB6AXuD1KBMHfRN1rcRo039KMoMWZr28bZui1tZzlljXcMMTybYZ53QUQIVfMj4zqhRNNjYTSeLpftbaSIxqJlmoO7Zk1NQfJphnkemS3bbjEi8T_1BKs1N7KdRwKBgSA5WvPWb2FdNF2-iBG4T5IciKpnqcMvWp35Pys0tMTw6B42CB1sixk9MIUD7D3yHSiyHAHuLB5Wlz7ySNBGd2aeDcssn22RLdOBrEv_-1CylNgZoQm62tVHcaqdyPu1Bz2pPdnudZGNVmH3NlzKTP";

// 1. Sticky Header Widget
class HomeSliverAppBar extends StatelessWidget {
  final UserProfile? user;
  final VoidCallback onNotificationTap;

  const HomeSliverAppBar({Key? key, this.user, required this.onNotificationTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
        ? user!.avatarUrl!
        : kDefaultAvatar;

    return SliverAppBar(
      backgroundColor: kBackgroundColor.withOpacity(0.8),
      pinned: true,
      floating: false,
      expandedHeight: 80.0,
      toolbarHeight: 80.0,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: SafeArea(
              child: SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kPrimaryColor, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(avatarUrl),
                              fit: BoxFit.cover,
                              onError: (_, __) => {},
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "TRANG NGƯỜI CHƠI",
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Chào mừng bạn!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        onPressed: onNotificationTap,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 2. Wallet Card Widget
class HomeWalletCard extends StatelessWidget {
  final double balance;
  final VoidCallback onDepositTap;

  const HomeWalletCard({
    Key? key,
    required this.balance,
    required this.onDepositTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Số dư ví",
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${NumberFormat('#,###').format(balance)}đ",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: onDepositTap,
              icon: const Icon(
                Icons.add_circle_outline,
                color: kBackgroundColor,
                size: 18,
              ),
              label: const Text(
                "Nạp tiền",
                style: TextStyle(
                  color: kBackgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Action Cards Widget
class HomeActionCards extends StatelessWidget {
  final VoidCallback onBookingTap;
  final VoidCallback onTournamentTap;

  const HomeActionCards({
    Key? key,
    required this.onBookingTap,
    required this.onTournamentTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCard(
          title: "Đặt sân Pickleball",
          subtitle: "Tìm và đặt sân trống gần bạn\nngay lập tức.",
          btnText: "Đặt ngay",
          btnIcon: Icons.calendar_today,
          bgIcon: Icons.sports_tennis,
          gradient: const LinearGradient(
            colors: [kPrimaryColor, Color(0xFF1FB35A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: onBookingTap,
          isPrimary: false, // Dark button on gradient
        ),
        const SizedBox(height: 12),
        _buildCard(
          title: "Tham gia giải đấu",
          subtitle: "Thử thách bản thân với các giải đấu\nchuyên nghiệp.",
          btnText: "Xem giải đấu",
          btnIcon: Icons.emoji_events,
          bgIcon: Icons.emoji_events,
          color: const Color(0xFF1E293B),
          onTap: onTournamentTap,
          isPrimary: true, // Primary button on dark bg
          bgIconOpacity: 0.08,
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required String btnText,
    required IconData btnIcon,
    required IconData bgIcon,
    required VoidCallback onTap,
    Gradient? gradient,
    Color? color,
    required bool isPrimary,
    double bgIconOpacity = 0.2,
  }) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (gradient != null)
                ? kPrimaryColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              bgIcon,
              size: 120,
              color: (gradient != null)
                  ? kBackgroundColor.withOpacity(bgIconOpacity)
                  : Colors.white.withOpacity(bgIconOpacity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: (gradient != null)
                            ? kBackgroundColor
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: (gradient != null)
                            ? kBackgroundColor.withOpacity(0.8)
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPrimary ? kPrimaryColor : kBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: const SizedBox.shrink(),
                    label: Row(
                      children: [
                        Text(
                          btnText,
                          style: TextStyle(
                            color: isPrimary ? kBackgroundColor : kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          btnIcon,
                          size: 16,
                          color: isPrimary ? kBackgroundColor : kPrimaryColor,
                        ),
                      ],
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Stats Row Widget
class HomeStatsRow extends StatelessWidget {
  final String tier;

  const HomeStatsRow({Key? key, required this.tier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatItem("Trận đấu sắp tới", "3", "Tuần này")),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem("Thứ hạng của bạn", tier, "DUPR")),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, String subLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  subLabel,
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 5. Tournament List Item Widget
class TournamentListItem extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentListItem({
    Key? key,
    required this.tournament,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine status color
    bool isOpen =
        tournament.status == 'Open' ||
        tournament.status == 'Upcoming' ||
        tournament.status == 'Registering';
    Color statusColor = isOpen ? kPrimaryColor : Colors.amber;
    if (tournament.status == 'Completed' || tournament.status == 'Cancelled') {
      statusColor = Colors.grey;
    }

    // Choose image based on id to vary visual (or use placeholder logic)
    // Here we stick to a nice placeholder
    const String placeholderImg =
        "https://lh3.googleusercontent.com/aida-public/AB6AXuBKJlslzevfIXxRBMkbIwZBp3wW6y1QZI9nIMZqKcWyT1RmKySTf9Hp3Z6LYALS1ubyk3bKXFKZmUzSW2j5F7fkCQ8hg2N3ga0GG7lSKn6Hj-ihTGl9ruilUs1zuEXfbRQOGHspfWOwGkGpHJJXhJsHuuv-Nfj9uGrJ2s9iMyCQL7BcIStHvTnRh0yaZfBWyl36QoQC4Nr6itdeWewEZIbXh6sTXQB0qQj4ttr4y0llphWWr70X3L8gjnBtihMj07r3iapQrMxmaVG_";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: NetworkImage(placeholderImg),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tournament.statusDisplay.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tournament.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Bắt đầu: ${DateFormat('dd/MM/yyyy').format(tournament.startDate)}",
                    style: const TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Phí: ${NumberFormat('#,###').format(tournament.entryFee)}đ",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Chi tiết",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
