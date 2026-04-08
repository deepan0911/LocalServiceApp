import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/models.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});
  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _labels  = ['All', 'Pending', 'Active', 'Completed', 'Cancelled'];
  final _statuses = [null, 'pending', 'accepted', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _labels.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<BookingManagementProvider>().fetchBookings(status: _statuses[_tabCtrl.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<BookingManagementProvider>().fetchBookings());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingManagementProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
          labelColor: AdminColors.primary,
          indicatorColor: AdminColors.primary,
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.bookings.isEmpty
              ? const Center(child: Text('No bookings found', style: TextStyle(color: AdminColors.textSub)))
              : RefreshIndicator(
                  onRefresh: () => provider.fetchBookings(status: _statuses[_tabCtrl.index]),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.bookings.length,
                    itemBuilder: (_, i) => _BookingRow(booking: provider.bookings[i]),
                  ),
                ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final AdminBooking booking;
  const _BookingRow({required this.booking});

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':     return AdminColors.warning;
      case 'accepted':    return AdminColors.success;
      case 'rejected':    return AdminColors.danger;
      case 'in_progress': return AdminColors.info;
      case 'completed':   return AdminColors.primary;
      default:            return AdminColors.textSub;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
              child: Text(booking.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text('${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}',
                style: const TextStyle(fontSize: 11, color: AdminColors.textSub)),
          ]),
          const SizedBox(height: 10),
          Text(booking.serviceType,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(booking.description,
              style: const TextStyle(color: AdminColors.textSub, fontSize: 13),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AdminColors.textSub),
            const SizedBox(width: 4),
            Text('Customer: ${booking.customer?.name ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: AdminColors.textSub)),
            const SizedBox(width: 16),
            const Icon(Icons.engineering_outlined, size: 14, color: AdminColors.textSub),
            const SizedBox(width: 4),
            Text('Worker: ${booking.worker?.user.name ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: AdminColors.textSub)),
          ]),
        ]),
      ),
    );
  }
}
