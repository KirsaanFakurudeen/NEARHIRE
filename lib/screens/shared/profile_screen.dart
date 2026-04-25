import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/rating_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // Seeker fields
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  String _availability = 'Full-Time';

  // Employer fields
  final _businessNameCtrl = TextEditingController();
  final _businessTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  bool _isLoading = false;
  String? _resumeFileName;
  double _averageRating = 0;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final doc = await _db.collection('users').doc(auth.user?.userId).get();
      final data = doc.data() ?? {};
      if (auth.role == AppConstants.roleSeeker) {
        _nameCtrl.text = data['fullName'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _skillsCtrl.text = (data['skills'] as List?)?.join(', ') ?? '';
        _experienceCtrl.text = data['experience'] ?? '';
        _availability = data['availability'] ?? 'Full-Time';
      } else {
        _businessNameCtrl.text = data['businessName'] ?? '';
        _businessTypeCtrl.text = data['type'] ?? '';
        _descriptionCtrl.text = data['description'] ?? '';
      }
      _averageRating = (data['averageRating'] ?? 0).toDouble();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _resumeFileName = result.files.single.name);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final Map<String, dynamic> data = auth.role == AppConstants.roleSeeker
          ? {
              'fullName': _nameCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
              'skills': _skillsCtrl.text.split(',').map((s) => s.trim()).toList(),
              'experience': _experienceCtrl.text.trim(),
              'availability': _availability,
            }
          : {
              'businessName': _businessNameCtrl.text.trim(),
              'type': _businessTypeCtrl.text.trim(),
              'description': _descriptionCtrl.text.trim(),
            };
      await _db.collection('users').doc(auth.user?.userId).update(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _skillsCtrl.dispose();
    _experienceCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().role;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (role == AppConstants.roleSeeker) ..._seekerFields()
                    else ..._employerFields(),
                    const SizedBox(height: 24),
                    Text('My Rating', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    RatingWidget(rating: _averageRating),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _seekerFields() => [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Full Name'),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _skillsCtrl,
          decoration: const InputDecoration(
            labelText: 'Skills (comma-separated)',
            hintText: 'e.g. Flutter, Dart, Firebase',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _experienceCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Experience'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _availability,
          decoration: const InputDecoration(labelText: 'Availability'),
          items: ['Full-Time', 'Part-Time', 'Weekends', 'Flexible']
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: (v) => setState(() => _availability = v!),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickResume,
          icon: const Icon(Icons.upload_file),
          label: Text(_resumeFileName ?? 'Upload Resume (PDF)'),
        ),
      ];

  List<Widget> _employerFields() => [
        TextFormField(
          controller: _businessNameCtrl,
          decoration: const InputDecoration(labelText: 'Business Name'),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _businessTypeCtrl,
          decoration: const InputDecoration(labelText: 'Business Type'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
      ];
}
