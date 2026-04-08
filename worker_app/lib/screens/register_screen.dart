import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../main.dart'; // To access AuthProvider and ApiClient
import 'dart:async';
import 'dart:io';

// Colors reused from main.dart
const Color _primary = Color(0xFF1E40AF);
const Color _error   = Color(0xFFEF4444);
const Color _success = Color(0xFF10B981);
const Color _warning = Color(0xFFF59E0B);

const List<String> _skillOptions = [
  'Electrician', 'Plumber', 'Carpenter', 'Painter',
  'AC Technician', 'Cleaning', 'Pest Control', 'Mason', 'Welder', 'Other',
];
const List<String> _idTypes = ['PAN', 'Passport', 'Driving License', 'Voter ID'];

class WorkerRegisterScreen extends StatefulWidget {
  const WorkerRegisterScreen({super.key});
  @override
  State<WorkerRegisterScreen> createState() => _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends State<WorkerRegisterScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Page 1: Personal
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _streetCtrl  = TextEditingController();
  final _cityCtrl    = TextEditingController();
  bool _obscure = true;

  // Verification States
  bool _emailVerified = false;
  bool _phoneVerified = false;
  String? _verificationId;
  int _emailTimer = 0;
  int _phoneTimer = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(bool isEmail) {
    if (isEmail) _emailTimer = 60; else _phoneTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_emailTimer > 0) _emailTimer--;
        if (_phoneTimer > 0) _phoneTimer--;
        if (_emailTimer == 0 && _phoneTimer == 0) timer.cancel();
      });
    });
  }

  Future<void> _sendEmailOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
      return;
    }
    final success = await context.read<AuthProvider>().sendEmailOtp(email);
    if (success) {
      _startTimer(true);
      _showOtpDialog(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Error sending OTP')));
    }
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid phone number')));
      return;
    }
    
    String phoneNumber = phone.startsWith('+') ? phone : '+91$phone';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() => _phoneVerified = true);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed')));
      },
      codeSent: (String verId, int? resendToken) {
        setState(() => _verificationId = verId);
        _startTimer(false);
        _showOtpDialog(false);
      },
      codeAutoRetrievalTimeout: (String verId) {
        _verificationId = verId;
      },
    );
  }

  void _showOtpDialog(bool isEmail) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Verify ${isEmail ? 'Email' : 'Phone'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit code sent to ${isEmail ? _emailCtrl.text : _phoneCtrl.text}'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(hintText: '000000'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (isEmail) {
                final success = await context.read<AuthProvider>().verifyEmailOtp(_emailCtrl.text.trim(), ctrl.text.trim());
                if (success) {
                  setState(() => _emailVerified = true);
                  Navigator.pop(ctx);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Invalid OTP')));
                }
              } else {
                try {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId!,
                    smsCode: ctrl.text.trim(),
                  );
                  await FirebaseAuth.instance.signInWithCredential(credential);
                  setState(() => _phoneVerified = true);
                  Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid SMS OTP')));
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
  final _p1Key = GlobalKey<FormState>();

  // Page 2: Skills
  final List<String> _selectedSkills = [];
  final _expCtrl  = TextEditingController(text: '1');
  final _bioCtrl  = TextEditingController();
  final _p2Key    = GlobalKey<FormState>();

  // Page 3: Identity
  final _aadhaarCtrl = TextEditingController();
  XFile? _aadhaarFront, _aadhaarBack, _additionalId;
  String? _additionalIdType;
  final _p3Key = GlobalKey<FormState>();

  bool _isLoading = false;
  final _picker = ImagePicker();

  void _next() {
    if (_page == 0) {
      if (!_p1Key.currentState!.validate()) return;
      if (!_emailVerified || !_phoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify both email and phone number')));
        return;
      }
    }
    if (_page == 1) {
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one skill'), backgroundColor: _warning));
        return;
      }
      if (!_p2Key.currentState!.validate()) return;
    }
    setState(() => _page++);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _back() {
    setState(() => _page--);
    _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _pickImage(String field) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() {
      if (field == 'front')  _aadhaarFront = file;
      if (field == 'back')   _aadhaarBack  = file;
      if (field == 'extra')  _additionalId  = file;
    });
  }

  Future<void> _submit() async {
    if (_aadhaarFront == null || _aadhaarBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aadhaar images required'), backgroundColor: _warning));
      return;
    }

    setState(() => _isLoading = true);
    try {
      Future<MultipartFile> _toFile(XFile f, String name) async {
        return kIsWeb 
          ? MultipartFile.fromBytes(await f.readAsBytes(), filename: name)
          : await MultipartFile.fromFile(f.path, filename: name);
      }

      final formData = FormData.fromMap({
        'name':          _nameCtrl.text.trim(),
        'email':         _emailCtrl.text.trim(),
        'phone':         _phoneCtrl.text.trim(),
        'password':      _passCtrl.text,
        'address[street]': _streetCtrl.text.trim(),
        'address[city]': _cityCtrl.text.trim(),
        'skills':        '[${_selectedSkills.map((s) => '"$s"').join(',')}]',
        'experience':    _expCtrl.text.trim(),
        'bio':           _bioCtrl.text.trim(),
        'aadhaarNumber': _aadhaarCtrl.text.trim(),
        'aadhaarFront':  await _toFile(_aadhaarFront!, 'aadhaar_front.jpg'),
        'aadhaarBack':   await _toFile(_aadhaarBack!,  'aadhaar_back.jpg'),
        if (_additionalIdType != null) 'additionalIdType': _additionalIdType,
        if (_additionalId != null) 'additionalId': await _toFile(_additionalId!, 'additional_id.jpg'),
      });

      final dio = Dio(BaseOptions(baseUrl: 'https://local-service-backend-k2aq.onrender.com/api'));
      await dio.post('/auth/register-worker', data: formData);

      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: _success), SizedBox(width: 10), Text('Registration Sent!')]),
        content: const Text('Your registration is under review. You will be notified once approved by the admin.'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
      ));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data['message'] ?? 'Registration failed'),
          backgroundColor: _error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Registration'),
        leading: _page > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back) : null,
      ),
      body: Column(children: [
        // Step indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: List.generate(3, (i) => Expanded(child: Container(
            height: 4, margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i <= _page ? _primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(100),
            ),
          )))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Text(['1. Personal Details', '2. Skills & Experience', '3. Identity Verification'][_page],
                style: const TextStyle(fontWeight: FontWeight.w700, color: _primary)),
            const Spacer(),
            Text('Step ${_page + 1} of 3', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [_page1(), _page2(), _page3()],
          ),
        ),
      ]),
    );
  }

  // ── Page 1: Personal Details ──
  Widget _page1() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _p1Key, child: Column(children: [
      _field(_nameCtrl,  'Full Name',    Icons.person_outline,   validator: _req),
      
      // Email Field with Verify
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          enabled: !_emailVerified,
          decoration: _dec('Email', Icons.email_outlined).copyWith(
            suffixIcon: _emailVerified
                ? const Icon(Icons.check_circle, color: _success)
                : TextButton(
                    onPressed: _emailTimer > 0 ? null : _sendEmailOtp,
                    child: Text(_emailTimer > 0 ? '${_emailTimer}s' : 'Verify'),
                  ),
          ),
          validator: (v) => v?.contains('@') != true ? 'Valid email required' : null,
        ),
      ),

      // Phone Field with Verify
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          enabled: !_phoneVerified,
          decoration: _dec('Phone Number', Icons.phone_outlined).copyWith(
            suffixIcon: _phoneVerified
                ? const Icon(Icons.check_circle, color: _success)
                : TextButton(
                    onPressed: _phoneTimer > 0 ? null : _sendPhoneOtp,
                    child: Text(_phoneTimer > 0 ? '${_phoneTimer}s' : 'Verify'),
                  ),
          ),
          validator: (v) => (v?.length ?? 0) < 10 ? 'Valid phone required' : null,
        ),
      ),

      _field(_passCtrl,  'Password',     Icons.lock_outline,     obscure: true, validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null),
      _field(_streetCtrl,'Street / Area',Icons.location_on_outlined, validator: _req),
      _field(_cityCtrl,  'City',         Icons.location_city_outlined, validator: _req),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _next, child: const Text('Next: Skills'))),
    ])),
  );

  // ── Page 2: Skills ──
  Widget _page2() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _p2Key, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select your skills *', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _skillOptions.map((s) {
        final sel = _selectedSkills.contains(s);
        return FilterChip(
          label: Text(s),
          selected: sel,
          onSelected: (_) => setState(() => sel ? _selectedSkills.remove(s) : _selectedSkills.add(s)),
          selectedColor: _primary.withOpacity(0.15),
          checkmarkColor: _primary,
          labelStyle: TextStyle(color: sel ? _primary : Colors.grey, fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
        );
      }).toList()),
      const SizedBox(height: 20),
      TextFormField(
        controller: _expCtrl,
        keyboardType: TextInputType.number,
        decoration: _dec('Years of Experience', Icons.work_outline),
        validator: _req,
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _bioCtrl,
        maxLines: 3,
        decoration: _dec('About yourself (optional)', Icons.info_outline),
      ),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _next, child: const Text('Next: Identity'))),
    ])),
  );

  // ── Page 3: Identity ──
  Widget _page3() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(key: _p3Key, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: _aadhaarCtrl,
        keyboardType: TextInputType.number,
        maxLength: 12,
        decoration: _dec('Aadhaar Number *', Icons.credit_card_outlined),
        validator: (v) => (v?.length ?? 0) != 12 ? '12-digit Aadhaar required' : null,
      ),
      const SizedBox(height: 16),
      const Text('Aadhaar Card Images *', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _imgPicker('Front Side', _aadhaarFront, () => _pickImage('front'))),
        const SizedBox(width: 12),
        Expanded(child: _imgPicker('Back Side', _aadhaarBack, () => _pickImage('back'))),
      ]),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _additionalIdType,
        decoration: _dec('Additional ID (optional)', Icons.badge_outlined),
        items: _idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setState(() => _additionalIdType = v),
      ),
      if (_additionalIdType != null) ...[
        const SizedBox(height: 12),
        _imgPicker('$_additionalIdType Image', _additionalId, () => _pickImage('extra')),
      ],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Registration'),
        ),
      ),
    ])),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl, keyboardType: type, obscureText: obscure,
        decoration: _dec(label, icon),
        validator: validator,
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF1F5F9),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  String? _req(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  Widget _imgPicker(String label, XFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file != null ? _success : Colors.grey.shade300, width: 1.5),
        ),
        child: file != null
            ? ClipRRect(borderRadius: BorderRadius.circular(11), child: kIsWeb ? Image.network(file.path, fit: BoxFit.cover) : Image.file(File(file.path), fit: BoxFit.cover))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt_outlined, color: Colors.grey.shade500),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), textAlign: TextAlign.center),
              ]),
      ),
    );
  }
}
