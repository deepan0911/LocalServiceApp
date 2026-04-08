import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/booking_provider.dart';
import '../chat/chat_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingModel _booking;
  double _rating = 4;
  final _reviewCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.pending;
      case 'accepted': return AppColors.accepted;
      case 'rejected': return AppColors.rejected;
      case 'in_progress': return AppColors.inProgress;
      case 'completed': return AppColors.completed;
      default: return AppColors.cancelled;
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<BookingProvider>().cancelBooking(_booking.id, reason: 'Customer cancelled');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _submitReview() async {
    await context.read<BookingProvider>().submitReview(_booking.id, _rating, _reviewCtrl.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_booking.status);
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Row(children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 10),
                Text(_booking.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 20),
            _DetailCard(children: [
              _Row('Service', _booking.serviceType),
              _Row('Scheduled', '${_booking.scheduledAt.day}/${_booking.scheduledAt.month}/${_booking.scheduledAt.year}'),
              _Row('Description', _booking.description),
            ]),
            if (_booking.worker != null) ...[
              const SizedBox(height: 16),
              const Text('Worker', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              _DetailCard(children: [
                _Row('Name', _booking.worker!.user.name),
                if (_booking.status == 'accepted' || _booking.status == 'in_progress' || _booking.status == 'completed')
                  _Row('Phone', _booking.worker!.user.phone),
              ]),
            ],
            // Chat button (available when pending or accepted)
            if (['pending', 'accepted', 'in_progress'].contains(_booking.status)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(booking: _booking))),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Open Chat with Worker'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            // Cancel button
            if (['pending', 'accepted'].contains(_booking.status)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            // Review section
            if (_booking.status == 'completed' && _booking.review == null) ...[
              const SizedBox(height: 24),
              const Text('Leave a Review', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                itemBuilder: (_, __) => const Icon(Icons.star, color: Color(0xFFFFB400)),
                onRatingUpdate: (r) => setState(() => _rating = r),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reviewCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Write your experience...'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _submitReview, child: const Text('Submit Review')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.bodyBold)),
        ],
      ),
    );
  }
}
