import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../models/models.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _labels   = ['Open', 'Under Review', 'Resolved'];
  final _statuses = ['open', 'under_review', 'resolved'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<ComplaintProvider>().fetchComplaints(status: _statuses[_tabCtrl.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ComplaintProvider>().fetchComplaints(status: 'open'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComplaintProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
          labelColor: AdminColors.primary,
          indicatorColor: AdminColors.primary,
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.complaints.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No complaints!', style: TextStyle(color: AdminColors.textSub)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.complaints.length,
                  itemBuilder: (_, i) => _ComplaintCard(complaint: provider.complaints[i]),
                ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _ComplaintCard({required this.complaint});

  Color _statusColor(String s) {
    switch (s) {
      case 'open':         return AdminColors.danger;
      case 'under_review': return AdminColors.warning;
      case 'resolved':     return AdminColors.success;
      default:             return AdminColors.textSub;
    }
  }

  Future<void> _resolve(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Resolve Complaint'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Enter resolution details:'),
        const SizedBox(height: 10),
        TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Resolution...')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.success),
          child: const Text('Resolve'),
        ),
      ],
    ));
    if (confirmed == true && context.mounted) {
      final ok = await context.read<ComplaintProvider>().resolveComplaint(complaint.id, ctrl.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Complaint resolved!' : 'Failed to resolve'),
          backgroundColor: ok ? AdminColors.success : AdminColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(complaint.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
              child: Text(complaint.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text('${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                style: const TextStyle(fontSize: 11, color: AdminColors.textSub)),
          ]),
          const SizedBox(height: 10),
          Text(complaint.subject,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(complaint.description,
              style: const TextStyle(color: AdminColors.textSub, fontSize: 13),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_outline, size: 13, color: AdminColors.textSub),
            const SizedBox(width: 4),
            Text('By: ${complaint.raisedBy?.name ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: AdminColors.textSub)),
            const SizedBox(width: 16),
            const Icon(Icons.person_off_outlined, size: 13, color: AdminColors.textSub),
            const SizedBox(width: 4),
            Text('Against: ${complaint.against?.name ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: AdminColors.textSub)),
          ]),
          if (complaint.resolution != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: AdminColors.success, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Resolution: ${complaint.resolution}',
                    style: const TextStyle(fontSize: 12, color: AdminColors.success))),
              ]),
            ),
          ],
          if (complaint.status == 'open') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _resolve(context),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Resolve'),
                style: ElevatedButton.styleFrom(backgroundColor: AdminColors.success),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
