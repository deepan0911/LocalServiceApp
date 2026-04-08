import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/register_screen.dart';
import 'screens/chat_screen.dart';

// ═══════════════════════════════════════════════════════
// COLORS & THEME
// ═══════════════════════════════════════════════════════
class AppColors {
  static const Color primary = Color(0xFF1E1B4B); // Deep Indigo
  static const Color primaryLight = Color(0xFF3730A3);
  static const Color accentSubtle = Color(0xFFF1F5F9); 
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const heading2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5);
  static const heading3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5);
  static const bodyBold = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const caption = TextStyle(fontSize: 12, color: Color(0xFF64748B));
}

ThemeData get workerTheme => ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, background: AppColors.background),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white, 
    foregroundColor: AppColors.textPrimary, 
    elevation: 0, 
    centerTitle: true,
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 0.5),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, 
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, 
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
  ),
  cardTheme: CardThemeData(
    color: Colors.white, 
    elevation: 0, 
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFF1F5F9)),
    ),
  ),
);

// ═══════════════════════════════════════════════════════
// API CLIENT
// ═══════════════════════════════════════════════════════
class ApiClient {
  static const baseUrl = kIsWeb ? 'http://localhost:5000/api' : 'http://192.168.29.204:5000/api';
  static final _storage = FlutterSecureStorage();
  static late Dio dio;

  static void init() {
    dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    ));
  }
}

// ═══════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════
class UserModel {
  final String id, name, email, phone;
  final String? profileImage;
  UserModel({required this.id, required this.name, required this.email, required this.phone, this.profileImage});
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['_id'] ?? j['id'] ?? '', name: j['name'] ?? '', email: j['email'] ?? '', phone: j['phone'] ?? '', profileImage: j['profileImage'],
  );
}

class WorkerModel {
  final String id, status;
  final List<String> skills;
  final double avgRating, experience;
  final bool isAvailable;
  WorkerModel({required this.id, required this.status, required this.skills, required this.avgRating, required this.experience, required this.isAvailable});
  factory WorkerModel.fromJson(Map<String, dynamic> j) => WorkerModel(
    id: j['_id'] ?? '', status: j['status'] ?? 'pending',
    skills: List<String>.from(j['skills'] ?? []),
    avgRating: (j['avgRating'] ?? 0).toDouble(), experience: (j['experience'] ?? 0).toDouble(),
    isAvailable: j['isAvailable'] ?? false,
  );
}

class BookingModel {
  final String id, serviceType, description, status;
  final Map<String, dynamic> address;
  final DateTime scheduledAt, createdAt;
  final UserModel? customer;
  final String? customerPhone, customerFullAddress;
  final List<String> images;

  BookingModel({required this.id, required this.serviceType, required this.description, required this.status,
      required this.address, required this.scheduledAt, required this.createdAt,
      this.customer, this.customerPhone, this.customerFullAddress, required this.images});

  factory BookingModel.fromJson(Map<String, dynamic> j) => BookingModel(
    id: j['_id'] ?? '', serviceType: j['serviceType'] ?? '', description: j['description'] ?? '',
    status: j['status'] ?? 'pending',
    address: j['address'] ?? {},
    scheduledAt: DateTime.tryParse(j['scheduledAt'] ?? '') ?? DateTime.now(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    customer: (j['customer'] is Map) ? UserModel.fromJson(Map<String, dynamic>.from(j['customer'])) : null,
    customerPhone: j['customerPhone'], customerFullAddress: j['customerFullAddress'],
    images: List<String>.from(j['images'] ?? []),
  );
}

// ═══════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  WorkerModel? _workerProfile;
  bool _isLoading = false;
  String? _error;
  final _storage = const FlutterSecureStorage();

  UserModel? get user => _user;
  WorkerModel? get workerProfile => _workerProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    try {
      final res = await ApiClient.dio.get('/auth/me');
      _user = UserModel.fromJson(res.data['user']);
      await loadWorkerProfile();
    } catch (_) {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await ApiClient.dio.post('/auth/login', data: {'email': email, 'password': password});
      await _storage.write(key: 'auth_token', value: res.data['token']);
      _user = UserModel.fromJson(res.data['user']);
      await loadWorkerProfile();
      _isLoading = false; notifyListeners(); return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Login failed';
      _isLoading = false; notifyListeners(); return false;
    }
  }

  Future<void> loadWorkerProfile() async {
    try {
      final res = await ApiClient.dio.get('/workers/me');
      _workerProfile = WorkerModel.fromJson(res.data['data']);
    } catch (_) {}
  }

  Future<void> toggleAvailability() async {
    if (_workerProfile == null) return;
    final newVal = !_workerProfile!.isAvailable;
    await ApiClient.dio.put('/workers/availability', data: {'isAvailable': newVal});
    await loadWorkerProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _user = null; _workerProfile = null; notifyListeners();
  }
}

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  Future<void> fetchBookings({String? status}) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await ApiClient.dio.get('/bookings/worker', queryParameters: status != null ? {'status': status} : {});
      _bookings = (res.data['data'] as List).map((b) => BookingModel.fromJson(b)).toList();
    } on DioException catch (e) {
      _error = e.response?.data['message'];
    }
    _isLoading = false; notifyListeners();
  }

  Future<bool> respond(String bookingId, String action, {String? reason}) async {
    try {
      await ApiClient.dio.put('/bookings/$bookingId/respond', data: {'action': action, 'rejectionReason': reason});
      await fetchBookings();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateStatus(String bookingId, String status) async {
    try {
      await ApiClient.dio.put('/bookings/$bookingId/status', data: {'status': status});
      await fetchBookings();
      return true;
    } catch (_) { return false; }
  }
}

// ═══════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.init();
  runApp(const WorkerApp());
}

class WorkerApp extends StatelessWidget {
  const WorkerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'ServiceHub – Worker',
        debugShowCheckedModeBanner: false,
        theme: workerTheme,
        home: const _SplashScreen(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SPLASH
// ═══════════════════════════════════════════════════════
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward().then((_) => _init());
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => auth.isAuthenticated ? const _WorkerHomeScreen() : const _LoginScreen()));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fade, 
            child: SlideTransition(
              position: _slide,
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Text('ServiceHub', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// LOGIN
// ═══════════════════════════════════════════════════════
class _LoginScreen extends StatefulWidget {
  const _LoginScreen();
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const _WorkerHomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(children: [
        const SizedBox(height: 80),
        const Center(
          child: Column(
            children: [
              Text('ServiceHub', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -1)),
              SizedBox(height: 12),
              Text('Worker Portal', style: AppTextStyles.body),
            ],
          ),
        ),
        const SizedBox(height: 60),
        TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v?.contains('@') != true ? 'Valid email required' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _passCtrl, obscureText: _obscure, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure))), validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: auth.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('New worker? ', style: TextStyle(color: Color(0xFF64748B))),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerRegisterScreen())),
            child: const Text('Register here', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ]),
      ])))),
    );
  }
}

// ═══════════════════════════════════════════════════════
// HOME SCREEN (Dashboard)
// ═══════════════════════════════════════════════════════
class _WorkerHomeScreen extends StatefulWidget {
  const _WorkerHomeScreen();
  @override
  State<_WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<_WorkerHomeScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: [
        const _DashboardTab(),
        const _BookingListTab(),
        const _WorkerProfileTab(),
      ]),
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
            _NavItem(icon: Icons.work_outline, activeIcon: Icons.work, isSelected: _idx == 1, onTap: () => setState(() => _idx = 1)),
            _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, isSelected: _idx == 2, onTap: () => setState(() => _idx = 2)),
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
          Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5), size: 24),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 4 : 0,
            height: 4,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ═══════ DASHBOARD TAB ═══════
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final worker = auth.workerProfile;
    return SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'ServiceHub',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          foreground: Paint()
            ..shader = AppColors.primaryGradient.createShader(
              const Rect.fromLTWH(0, 0, 200, 40),
            ),
        ),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dashboard', style: AppTextStyles.heading2),
        ]),
        const Spacer(),
        if (worker != null) Switch.adaptive(
          value: worker.isAvailable,
          activeColor: AppColors.success,
          onChanged: (_) => auth.toggleAvailability(),
        ),
      ]),
      if (worker != null) ...[
        const SizedBox(height: 6),
        Text(worker.isAvailable ? '🟢 Available for bookings' : '🔴 Currently unavailable', style: AppTextStyles.caption),
      ],
      const SizedBox(height: 24),
      if (worker?.status == 'pending') ...[
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.zero, border: Border.all(color: AppColors.warning.withOpacity(0.3))), child: const Row(children: [Icon(Icons.hourglass_empty, color: AppColors.warning), SizedBox(width: 12), Expanded(child: Text('Your account is pending admin approval. You will be notified once approved.', style: AppTextStyles.body))])),
      ],
      if (worker != null) ...[
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _StatCard(label: 'Rating', value: worker.avgRating.toStringAsFixed(1), icon: Icons.star, color: const Color(0xFFFFB400))),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Experience', value: '${worker.experience.toInt()} yrs', icon: Icons.work, color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(label: 'Skills', value: '${worker.skills.length}', icon: Icons.category, color: AppColors.success)),
          const SizedBox(width: 12),
          const Expanded(child: _StatCard(label: 'Status', value: 'Active', icon: Icons.verified, color: Color(0xFF8B5CF6))),
        ]),
      ],
      const SizedBox(height: 24),
      const Text('Quick Tips', style: AppTextStyles.heading3),
      const SizedBox(height: 12),
      Card(child: Column(children: const [
        ListTile(leading: Icon(Icons.chat_bubble_outline, color: AppColors.primary), title: Text('Chat before accepting', style: AppTextStyles.bodyBold), subtitle: Text('Discuss details with customers via live chat', style: AppTextStyles.body)),
        Divider(height: 1, indent: 16),
        ListTile(leading: Icon(Icons.info_outline, color: AppColors.warning), title: Text('Customer info revealed after acceptance', style: AppTextStyles.bodyBold), subtitle: Text('Phone & address shown only when you accept', style: AppTextStyles.body)),
      ])),
    ])));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.zero), child: Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: AppTextStyles.caption),
      ]),
    ]));
  }
}

// ═══════ BOOKING LIST TAB ═══════
class _BookingListTab extends StatefulWidget {
  const _BookingListTab();
  @override
  State<_BookingListTab> createState() => _BookingListTabState();
}

class _BookingListTabState extends State<_BookingListTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BookingProvider>().fetchBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(controller: _tabCtrl, tabs: const [Tab(text: 'Pending'), Tab(text: 'Active'), Tab(text: 'History')],
          labelColor: AppColors.primary, indicatorColor: AppColors.primary),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _WorkerBookingList(statusFilter: 'pending'),
          _WorkerBookingList(statusFilter: 'accepted'),
          _WorkerBookingList(statusFilter: 'completed'),
        ],
      ),
    );
  }
}

class _WorkerBookingList extends StatelessWidget {
  final String statusFilter;
  const _WorkerBookingList({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    final filtered = provider.bookings.where((b) => b.status == statusFilter).toList();
    if (filtered.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 12),
      Text('No $statusFilter bookings', style: AppTextStyles.body),
    ]));
    return RefreshIndicator(
      onRefresh: () async => context.read<BookingProvider>().fetchBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _WorkerBookingCard(booking: filtered[i]),
      ),
    );
  }
}

class _WorkerBookingCard extends StatelessWidget {
  final BookingModel booking;
  const _WorkerBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == 'pending';
    final isAccepted = booking.status == 'accepted';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(100)), child: Text(booking.serviceType, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
          const Spacer(),
          Text('${booking.scheduledAt.day}/${booking.scheduledAt.month}/${booking.scheduledAt.year}', style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 10),
        Text(booking.description, style: AppTextStyles.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        if (booking.customer != null) Row(children: [const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4), Text(booking.customer!.name, style: AppTextStyles.caption)]),
        const SizedBox(height: 12),
        if (isPending) Column(children: [
          // Chat button before decision
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerChatScreen(
              bookingId: booking.id,
              customerName: booking.customer?.name ?? 'Customer',
              serviceType: booking.serviceType,
            ))),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Chat with Customer'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
          )),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => context.read<BookingProvider>().respond(booking.id, 'reject', reason: 'Not available'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              child: const Text('Decline'),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => context.read<BookingProvider>().respond(booking.id, 'accept'),
              child: const Text('Accept'),
            )),
          ]),
        ]),
        if (isAccepted) ...[
          if (booking.customerPhone != null) Text('📞 ${booking.customerPhone}', style: AppTextStyles.bodyBold),
          if (booking.customerFullAddress != null) Text('📍 ${booking.customerFullAddress}', style: AppTextStyles.body),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => context.read<BookingProvider>().updateStatus(booking.id, 'completed'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Mark as Completed'),
          )),
        ],
      ])),
    );
  }
}

// ═══════ PROFILE TAB ═══════
class _WorkerProfileTab extends StatelessWidget {
  const _WorkerProfileTab();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final worker = auth.workerProfile;
    return SafeArea(child: SingleChildScrollView(child: Column(children: [
      Container(width: double.infinity, decoration: const BoxDecoration(gradient: AppColors.primaryGradient), padding: const EdgeInsets.only(top: 32, bottom: 48), child: Column(children: [
        CircleAvatar(radius: 50, backgroundColor: Colors.white.withOpacity(0.2), child: Text((user?.name ?? 'W')[0], style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800))),
        const SizedBox(height: 12),
        Text(user?.name ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        if (worker != null) Text(worker.skills.join(' • '), style: const TextStyle(color: Colors.white70)),
      ])),
      Transform.translate(offset: const Offset(0, -24), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.badge_outlined, color: AppColors.primary), title: const Text('Status', style: AppTextStyles.caption), subtitle: Text(worker?.status.toUpperCase() ?? '', style: AppTextStyles.bodyBold)),
        ListTile(leading: const Icon(Icons.phone_outlined, color: AppColors.primary), title: const Text('Phone', style: AppTextStyles.caption), subtitle: Text(user?.phone ?? '', style: AppTextStyles.bodyBold)),
        ListTile(leading: const Icon(Icons.email_outlined, color: AppColors.primary), title: const Text('Email', style: AppTextStyles.caption), subtitle: Text(user?.email ?? '', style: AppTextStyles.bodyBold)),
      ])))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () async {
          await auth.logout();
          if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const _LoginScreen()), (_) => false);
        },
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text('Logout', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 14)),
      ))),
    ])));
  }
}
