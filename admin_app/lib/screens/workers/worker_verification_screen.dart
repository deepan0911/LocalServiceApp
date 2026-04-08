import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/models.dart';

class WorkerVerificationScreen extends StatefulWidget {
  const WorkerVerificationScreen({super.key});
  @override
  State<WorkerVerificationScreen> createState() => _WorkerVerificationScreenState();
}

class _WorkerVerificationScreenState extends State<WorkerVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['Pending', 'Approved', 'Rejected'];
  final _statuses = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<WorkerVerificationProvider>().fetchWorkers(status: _statuses[_tabCtrl.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<WorkerVerificationProvider>().fetchWorkers(status: 'pending'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkerVerificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Verification'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AdminColors.primary,
          indicatorColor: AdminColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _statuses.map((s) =>
          provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.workers.isEmpty
              ? _emptyState(s)
              : RefreshIndicator(
                  onRefresh: () => provider.fetchWorkers(status: s),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.workers.length,
                    itemBuilder: (_, i) => _WorkerCard(worker: provider.workers[i], currentTab: s),
                  ),
                ),
        ).toList(),
      ),
    );
  }

  Widget _emptyState(String status) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('No $status workers', style: const TextStyle(color: AdminColors.textSub)),
    ]));
  }
}

class _WorkerCard extends StatelessWidget {
  final AdminWorker worker;
  final String currentTab;
  const _WorkerCard({required this.worker, required this.currentTab});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AdminColors.primary,
            child: Text(worker.user.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          title: Text(worker.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(worker.user.phone),
            Text(worker.skills.join(', '), style: const TextStyle(color: AdminColors.primary, fontSize: 12)),
          ]),
          trailing: _StatusBadge(worker.status),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            const Icon(Icons.verified, size: 14, color: AdminColors.textSub),
            const SizedBox(width: 4),
            Text('Aadhaar: ${worker.aadhaarNumber ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: AdminColors.textSub)),
            const SizedBox(width: 12),
            const Icon(Icons.work_outline, size: 14, color: AdminColors.textSub),
            const SizedBox(width: 4),
            Text('${worker.experience.toInt()} yrs',
                style: const TextStyle(fontSize: 12, color: AdminColors.textSub)),
          ]),
        ),
        // ID Document thumbnails
        if (worker.aadhaarFront != null || worker.aadhaarBack != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              if (worker.aadhaarFront != null)
                _DocThumbnail('Aadhaar Front', worker.aadhaarFront!, context),
              const SizedBox(width: 10),
              if (worker.aadhaarBack != null)
                _DocThumbnail('Aadhaar Back', worker.aadhaarBack!, context),
              if (worker.additionalIdImage != null) ...[
                const SizedBox(width: 10),
                _DocThumbnail(worker.additionalIdType ?? 'ID', worker.additionalIdImage!, context),
              ],
            ]),
          ),
        // Action buttons (only for pending)
        if (currentTab == 'pending')
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(context, worker.id),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.danger,
                  side: const BorderSide(color: AdminColors.danger),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _approve(context, worker.id),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.success),
              )),
            ]),
          ),
      ]),
    );
  }

  Future<void> _approve(BuildContext context, String id) async {
    final ok = await context.read<WorkerVerificationProvider>().verifyWorker(id, 'approve');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Worker approved successfully' : 'Failed to approve'),
        backgroundColor: ok ? AdminColors.success : AdminColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _showRejectDialog(BuildContext context, String id) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Reject Worker'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Please provide a reason for rejection:'),
        const SizedBox(height: 12),
        TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Reason...')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger), child: const Text('Reject')),
      ],
    ));
    if (confirmed == true && context.mounted) {
      await context.read<WorkerVerificationProvider>().verifyWorker(id, 'reject', reason: reasonCtrl.text);
    }
  }

  Widget _DocThumbnail(String label, String url, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FullImageView(url: url, title: label))),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(imageUrl: url, width: 70, height: 50, fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 70, height: 50, color: Colors.grey.shade200)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AdminColors.textSub)),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': AdminColors.warning,
      'approved': AdminColors.success,
      'rejected': AdminColors.danger,
      'suspended': AdminColors.textSub,
    };
    final color = colors[status] ?? AdminColors.textSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(100)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _FullImageView extends StatelessWidget {
  final String url, title;
  const _FullImageView({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PhotoView(imageProvider: CachedNetworkImageProvider(url), minScale: PhotoViewComputedScale.contained),
    );
  }
}
