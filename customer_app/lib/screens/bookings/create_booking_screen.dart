import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/booking_provider.dart';
import '../home/home_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  final WorkerModel worker;
  const CreateBookingScreen({super.key, required this.worker});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _selectedService;
  DateTime? _scheduledAt;
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.worker.skills.isNotEmpty ? widget.worker.skills.first : null;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 75);
    setState(() => _images.addAll(files));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date & time'), backgroundColor: AppColors.warning));
      return;
    }
    final provider = context.read<BookingProvider>();
    final success = await provider.createBooking(
      workerId: widget.worker.id,
      serviceType: _selectedService!,
      description: _descCtrl.text.trim(),
      address: {'street': _streetCtrl.text.trim(), 'city': _cityCtrl.text.trim()},
      scheduledAt: _scheduledAt!,
      imagePaths: _images.map((f) => f.path).toList(),
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Booking created! Waiting for worker response.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker header
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(widget.worker.user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(widget.worker.user.name, style: AppTextStyles.bodyBold),
                  subtitle: Text(widget.worker.skills.join(', '), style: AppTextStyles.caption),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Service Type', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: const InputDecoration(hintText: 'Select service'),
                items: widget.worker.skills.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedService = v),
                validator: (v) => v == null ? 'Select a service' : null,
              ),
              const SizedBox(height: 20),
              const Text('Problem Description', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Describe the issue in detail...'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Service Address', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              TextFormField(
                controller: _streetCtrl,
                decoration: const InputDecoration(labelText: 'Street / Area', prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
                validator: (v) => v == null || v.trim().isEmpty ? 'City required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Schedule Date & Time', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _scheduledAt != null
                            ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}  ${_scheduledAt!.hour.toString().padLeft(2, '0')}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                            : 'Select date and time',
                        style: _scheduledAt != null ? AppTextStyles.bodyBold : AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Attach Photos (optional)', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.map((f) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(f.path), width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(f)),
                          child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  )),
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  child: provider.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
