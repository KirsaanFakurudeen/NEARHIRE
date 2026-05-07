import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/application_provider.dart';
import '../../screens/shared/rating_screen.dart';
import 'package:provider/provider.dart';

class ApplicantProfileScreen extends StatefulWidget {
  final String applicationId;
  final String seekerId;
  final String jobId;

  const ApplicantProfileScreen({
    super.key,
    required this.applicationId,
    required this.seekerId,
    this.jobId = '',
  });

  @override
  State<ApplicantProfileScreen> createState() => _ApplicantProfileScreenState();
}

class _ApplicantProfileScreenState extends State<ApplicantProfileScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.seekerId)
          .get();
      if (!doc.exists) throw Exception('Seeker not found');
      setState(() => _data = doc.data());
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
    final name = _data?['fullName'] ?? 'Applicant';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
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
                            name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(child: Text(name, style: Theme.of(context).textTheme.displayMedium)),
                      const SizedBox(height: 24),
                      _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: _data?['phone'] ?? ''),
                      if (_data?['experience'] != null)
                        _InfoRow(icon: Icons.work_outline, label: 'Experience', value: _data!['experience']),
                      if (_data?['availability'] != null)
                        _InfoRow(icon: Icons.schedule_outlined, label: 'Availability', value: _data!['availability']),
                      if (_data?['skills'] != null && (_data!['skills'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: (_data!['skills'] as List)
                              .map((s) => Chip(
                                    label: Text(s.toString(),
                                        style: const TextStyle(color: AppTheme.textPrimary)),
                                    backgroundColor: AppTheme.backgroundLight,
                                  ))
                              .toList(),
                        ),
                      ],
                      if (_data?['resumeUrl'] != null) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('View Resume'),
                          onPressed: () => launchUrl(Uri.parse(_data!['resumeUrl'])),
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Open Chat'),
                        onPressed: () => Navigator.of(context).pushNamed('/chat', arguments: {
                          'applicationId': widget.applicationId,
                          'otherUserId': widget.seekerId,
                          'otherUserName': name,
                          'otherUserRole': 'Job Seeker',
                        }),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Schedule Interview'),
                        onPressed: _scheduleInterview,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.feedback_outlined),
                        label: const Text('Give Feedback'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                        onPressed: () => RatingScreen.show(
                          context,
                          jobId: widget.jobId,
                          ratedUserId: widget.seekerId,
                          ratedUserName: name,
                        ),
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
