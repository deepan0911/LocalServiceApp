import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';
import '../workers/worker_verification_screen.dart';
import '../bookings/admin_bookings_screen.dart';
import '../users/users_screen.dart';
import '../complaints/complaints_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _idx = 0;

  final List<Widget> _pages = const [
    _DashboardHome(),
    WorkerVerificationScreen(),
    AdminBookingsScreen(),
    UsersScreen(),
    ComplaintsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, isSelected: _idx == 0, onTap: () => setState(() => _idx = 0)),
            _NavItem(icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user, isSelected: _idx == 1, onTap: () => setState(() => _idx = 1)),
            _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, isSelected: _idx == 2, onTap: () => setState(() => _idx = 2)),
            _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, isSelected: _idx == 3, onTap: () => setState(() => _idx = 3)),
            _NavItem(icon: Icons.report_outlined, activeIcon: Icons.report, isSelected: _idx == 4, onTap: () => setState(() => _idx = 4)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? AdminColors.primary : AdminColors.textSub, size: 24),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 4 : 0,
            height: 4,
            decoration: const BoxDecoration(color: AdminColors.primary, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Home Tab ───────────────────────────────────────────────────────
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();
  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().fetchAnalytics();
      context.read<WorkerVerificationProvider>().fetchWorkers(status: 'pending');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final analytics = analyticsProvider.analytics;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'ServiceHub',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            foreground: Paint()
              ..shader = AdminColors.primaryGrad.createShader(
                const Rect.fromLTWH(0, 0, 200, 40),
              ),
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AnalyticsProvider>().fetchAnalytics(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AdminColors.textPrime)),
            const SizedBox(height: 4),
            const Text('Here\'s your platform overview', style: TextStyle(color: AdminColors.textSub)),
            const SizedBox(height: 24),

            // Stats grid
            if (analyticsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (analytics != null) ...[
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                   _StatCard('Customers', analytics.totalCustomers.toString(), Icons.people),
                   _StatCard('Workers', analytics.totalWorkers.toString(), Icons.engineering),
                   _StatCard('Total Bookings', analytics.totalBookings.toString(), Icons.receipt_long),
                   _StatCard('Pending Workers', analytics.pendingWorkers.toString(), Icons.hourglass_empty),
                   _StatCard('Active Bookings', analytics.activeBookings.toString(), Icons.play_circle),
                   _StatCard('Revenue', '₹${analytics.totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee),
                ],
              ),
              const SizedBox(height: 28),

              // Top Services
              const Text('Top Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.textPrime)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: analytics.topServices.map((s) {
                      final maxCount = analytics.topServices.isNotEmpty
                          ? (analytics.topServices.first['count'] ?? 1) as int
                          : 1;
                      final count = (s['count'] ?? 0) as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(s['_id'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            Text('$count bookings', style: const TextStyle(color: AdminColors.textSub, fontSize: 12)),
                          ]),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: maxCount > 0 ? count / maxCount : 0,
                            backgroundColor: AdminColors.primary.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.primary),
                            borderRadius: BorderRadius.zero,
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Booking status breakdown
              const Text('Booking Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.textPrime)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: analytics.bookingsByStatus.map((s) {
                      final statusColors = {
                        'pending': AdminColors.primary.withOpacity(0.2),
                        'accepted': AdminColors.primary.withOpacity(0.4),
                        'rejected': AdminColors.primary.withOpacity(0.9),
                        'in_progress': AdminColors.primary.withOpacity(0.6),
                        'completed': AdminColors.primary,
                        'cancelled': AdminColors.textSub.withOpacity(0.3),
                      };
                      final status = s['_id'] as String? ?? '';
                      final color = statusColors[status] ?? AdminColors.textSub;
                      return ListTile(
                        dense: true,
                        leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        title: Text(status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textPrime)),
                        trailing: Text('${s['count']}',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AdminColors.primary)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(color: AdminColors.bg, borderRadius: BorderRadius.zero),
          child: Icon(icon, color: AdminColors.primary, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AdminColors.primary, letterSpacing: -0.5)),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.textSub)),
      ]),
    );
  }
}
