import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../bookings/create_booking_screen.dart';

class WorkerDetailScreen extends StatelessWidget {
  final WorkerModel worker;
  const WorkerDetailScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                  Positioned(
                    bottom: 40, left: 0, right: 0,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: worker.user.profileImage != null
                              ? CachedNetworkImage(imageUrl: worker.user.profileImage!, width: 90, height: 90, fit: BoxFit.cover)
                              : Container(
                                  width: 90, height: 90,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Text(worker.user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(worker.skills.join(' • '), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatChip(label: 'Rating', value: worker.avgRating.toStringAsFixed(1), icon: Icons.star, color: AppColors.primary),
                        _StatChip(label: 'Experience', value: '${worker.experience.toInt()} yrs', icon: Icons.work_history, color: AppColors.primary.withOpacity(0.8)),
                        _StatChip(label: 'Bookings', value: '${worker.totalBookings}', icon: Icons.receipt_long, color: AppColors.primary.withOpacity(0.7)),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (worker.bio != null && worker.bio!.isNotEmpty) ...[
                    const Text('About', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(worker.bio!, style: AppTextStyles.body),
                    const SizedBox(height: 24),
                  ],
                  const Text('Skills', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: worker.skills.map((s) => Chip(
                      label: Text(s),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  RatingBarIndicator(
                    rating: worker.avgRating,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.primary),
                    itemCount: 5,
                    itemSize: 20,
                  ),
                  const SizedBox(height: 6),
                  Text('${worker.avgRating.toStringAsFixed(1)} out of 5 (${worker.totalRatings} reviews)', style: AppTextStyles.caption),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateBookingScreen(worker: worker)),
            ),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Book Now'),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
