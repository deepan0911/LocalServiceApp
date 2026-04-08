import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/worker_provider.dart';
import '../../models/models.dart';
import 'worker_detail_screen.dart';

class WorkerListScreen extends StatefulWidget {
  final String? filterSkill;

  const WorkerListScreen({super.key, this.filterSkill});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  String? _selectedSkill;
  final _scrollCtrl = ScrollController();

  static const List<String> _skills = [
    'All', 'Electrician', 'Plumber', 'Carpenter', 'Painter', 'AC Technician', 'Cleaning', 'Pest Control', 'Mason',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSkill = widget.filterSkill;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkers(refresh: true));
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<WorkerProvider>().fetchWorkers(skill: _selectedSkill == 'All' ? null : _selectedSkill);
    }
  }

  void _loadWorkers({bool refresh = false}) {
    context.read<WorkerProvider>().fetchWorkers(
      skill: _selectedSkill == 'All' ? null : _selectedSkill,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkerProvider>();
    return Scaffold(
      appBar: widget.filterSkill != null ? AppBar(title: Text(widget.filterSkill!)) : null,
      body: Column(
        children: [
          if (widget.filterSkill == null) ...[
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('Find Professionals', style: AppTextStyles.heading2),
              ),
            ),
          ],
          // Skill filter chips
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _skills.length,
              itemBuilder: (context, i) {
                final skill = _skills[i];
                final isSelected = _selectedSkill == skill || (_selectedSkill == null && skill == 'All');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedSkill = skill == 'All' ? null : skill);
                      _loadWorkers(refresh: true);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.workers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.workers.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.workers.length + (provider.hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == provider.workers.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          return _WorkerCard(worker: provider.workers[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 72, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('No workers available', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          const Text('Try a different category or check back later', style: AppTextStyles.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: worker.user.profileImage != null
                    ? CachedNetworkImage(
                        imageUrl: worker.user.profileImage!,
                        width: 64, height: 64, fit: BoxFit.cover,
                        placeholder: (_, __) => const _AvatarPlaceholder(),
                      )
                    : const _AvatarPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(worker.user.name, style: AppTextStyles.bodyBold, overflow: TextOverflow.ellipsis)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                          ),
                          child: const Text('Available', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(worker.skills.join(', '), style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: worker.avgRating,
                          itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.primary),
                          itemCount: 5,
                          itemSize: 14,
                        ),
                        const SizedBox(width: 6),
                        Text('${worker.avgRating.toStringAsFixed(1)} (${worker.totalRatings})', style: AppTextStyles.caption),
                        const SizedBox(width: 12),
                        const Icon(Icons.work_outline, size: 13, color: AppColors.textLight),
                        const SizedBox(width: 3),
                        Text('${worker.experience} yrs', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 32),
    );
  }
}
