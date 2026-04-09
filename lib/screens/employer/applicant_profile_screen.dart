import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/seeker_profile.dart';
import '../../widgets/rating_widget.dart';
import '../../providers/application_provider.dart';
import 'package:provider/provider.dart';

class ApplicantProfileScreen extends StatefulWidget {
  final String applicationId;
  final String seekerId;

  const ApplicantProfileScreen({
    super.key,
    required this.applicationId,
    required this.seekerId,
  });

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  final ApiService _api = ApiService();
  SeekerProfile? _profile;
  String? _seekerName;
  String? _seekerPhone;
  double _rating = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _api.get('/seekers/${widget.seekerId}');
      final data = res.data;
      setState(() {
        _profile = SeekerProfile.fromJson(data['profile'] ?? {});
        _seekerName = data['fullName'] ?? '';
        _seekerPhone = data['phone'] ?? '';
        _rating = (data['averageRating'] ?? 0).toDouble();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleInterview() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      await context.read<ApplicationProvider>().scheduleInterview(widget.applicationId, scheduled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview scheduled!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_seekerName ?? 'Applicant')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            (_seekerName ?? 'A').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(_seekerName ?? '', style: Theme.of(context).textTheme.displayMedium),
                      ),
                      Center(child: RatingWidget(rating: _rating)),
                      const SizedBox(height: 24),
                      _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: _seekerPhone ?? ''),
                      if (_profile != null) ...[
                        _InfoRow(icon: Icons.work_outline, label: 'Experience', value: _profile!.experience),
                        _InfoRow(icon: Icons.schedule_outlined, label: 'Availability', value: _profile!.availability),
                        const SizedBox(height: 12),
                        Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _profile!.skills
                              .map((s) => Chip(label: Text(s)))
                              .toList(),
                        ),
                        if (_profile!.resumeUrl != null) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('View Resume'),
                            onPressed: () => launchUrl(Uri.parse(_profile!.resumeUrl!)),
                          ),
                        ],
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Open Chat'),
                        onPressed: () => Navigator.of(context).pushNamed('/chat', arguments: {
                          'applicationId': widget.applicationId,
                          'otherUserId': widget.seekerId,
                          'otherUserName': _seekerName ?? '',
                          'otherUserRole': 'Job Seeker',
                        }),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Schedule Interview'),
                        onPressed: _scheduleInterview,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
