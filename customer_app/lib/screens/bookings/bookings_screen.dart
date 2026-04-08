import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../models/models.dart';
import 'booking_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = const ['Active', 'Completed', 'Cancelled'];
  final _statuses = [null, 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<BookingProvider>().fetchBookings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: List.generate(_tabs.length, (i) => _BookingList(statusFilter: _statuses[i])),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String? statusFilter;
  const _BookingList({this.statusFilter});

  bool _matches(BookingModel b) {
    if (statusFilter == null) return ['pending', 'accepted', 'in_progress'].contains(b.status);
    return b.status == statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    final filtered = provider.bookings.where(_matches).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('No bookings here', style: AppTextStyles.body),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<BookingProvider>().fetchBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (_, i) => BookingCard(booking: filtered[i]),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  const BookingCard({super.key, required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.pending; // Slate
      case 'accepted': return AppColors.accepted; // Indigo Light
      case 'rejected': return AppColors.error.withOpacity(0.8); // Muted Error
      case 'in_progress': return AppColors.primary; // Indigo
      case 'completed': return AppColors.primary; // Indigo
      default: return AppColors.cancelled; // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(100)),
                    child: Text(booking.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Text('${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 12),
              Text(booking.serviceType, style: AppTextStyles.bodyBold),
              const SizedBox(height: 4),
              Text(booking.description, style: AppTextStyles.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (booking.worker != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(booking.worker!.user.name, style: AppTextStyles.caption),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
