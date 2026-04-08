import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

// Provider for user management
class UserManagementProvider extends ChangeNotifier {
  List<AdminUser> _users = [];
  bool _isLoading = false;

  List<AdminUser> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers({String? role}) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiClient.dio.get('/admin/users',
          queryParameters: {'limit': 50, if (role != null) 'role': role});
      _users = (res.data['data'] as List).map((u) => AdminUser.fromJson(u)).toList();
    } catch (_) {}
    _isLoading = false; notifyListeners();
  }

  Future<void> toggleStatus(String userId) async {
    try {
      await ApiClient.dio.put('/admin/users/$userId/status');
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        final u = _users[idx];
        _users[idx] = AdminUser(
          id: u.id, name: u.name, email: u.email, phone: u.phone,
          role: u.role, isActive: !u.isActive, createdAt: u.createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late UserManagementProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = UserManagementProvider();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _provider.fetchUsers(role: _tabCtrl.index == 0 ? 'customer' : 'worker');
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.fetchUsers(role: 'customer'));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          bottom: TabBar(
            controller: _tabCtrl,
            tabs: const [Tab(text: 'Customers'), Tab(text: 'Workers')],
            labelColor: AdminColors.primary,
            indicatorColor: AdminColors.primary,
          ),
        ),
        body: Consumer<UserManagementProvider>(builder: (_, p, __) =>
          p.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabCtrl, children: [
                _UserList(users: p.users, provider: p),
                _UserList(users: p.users, provider: p),
              ]),
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<AdminUser> users;
  final UserManagementProvider provider;
  const _UserList({required this.users, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: AdminColors.textSub)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) => _UserCard(user: users[i], onToggle: () => provider.toggleStatus(users[i].id)),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onToggle;
  const _UserCard({required this.user, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? AdminColors.primary : AdminColors.textSub,
          child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.email, style: const TextStyle(fontSize: 12)),
          Text(user.phone, style: const TextStyle(fontSize: 12, color: AdminColors.textSub)),
        ]),
        trailing: Switch.adaptive(
          value: user.isActive,
          activeColor: AdminColors.success,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}
