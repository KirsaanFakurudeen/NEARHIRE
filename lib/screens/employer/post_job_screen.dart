import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/constants/app_constants.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _payCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  String _jobType = 'full-time';
  double _radius = AppConstants.defaultRadiusKm;

  static const _jobTypes = ['full-time', 'part-time', 'freelance', 'gig', 'shift-based'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().refreshLocation();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _payCtrl.dispose();
    _scheduleCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final loc = context.read<LocationProvider>();
    if (!loc.hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for GPS location...')),
      );
      return;
    }
    try {
      await context.read<JobProvider>().postJob({
        'employerId': auth.user?.userId ?? '',
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'payAmount': double.parse(_payCtrl.text.trim()),
        'jobType': _jobType,
        'schedule': _scheduleCtrl.text.trim(),
        'requiredSkills': _skillsCtrl.text.split(',').map((s) => s.trim()).toList(),
        'latitude': loc.latitude,
        'longitude': loc.longitude,
        'radiusKm': _radius,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job posted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final isLoading = context.watch<JobProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Job Title'),
                    validator: (v) => Validators.required(v, 'Job title'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Job Description',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => Validators.required(v, 'Description'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _payCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pay Amount',
                      prefixText: '\$ ',
                    ),
                    validator: Validators.payAmount,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _jobType,
                    decoration: const InputDecoration(labelText: 'Job Type'),
                    items: _jobTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _jobType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _scheduleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Schedule',
                      hintText: 'e.g. Weekdays 9am–5pm',
                    ),
                    validator: (v) => Validators.required(v, 'Schedule'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skillsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Required Skills (comma-separated)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Search Radius: ${_radius.toStringAsFixed(0)} km',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _radius,
                    min: AppConstants.minRadiusKm,
                    max: AppConstants.maxRadiusKm,
                    divisions: 49,
                    label: '${_radius.toStringAsFixed(0)} km',
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                  const SizedBox(height: 16),
                  Text('Job Location', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (loc.hasLocation)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      child: SizedBox(
                        height: 160,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(loc.latitude!, loc.longitude!),
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('job_loc'),
                              position: LatLng(loc.latitude!, loc.longitude!),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: const Text('Post Job'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
