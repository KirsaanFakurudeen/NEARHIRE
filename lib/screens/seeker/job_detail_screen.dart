import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/job_listing.dart';
import '../../widgets/rating_widget.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobListing? _job;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    try {
      final job = await context.read<JobProvider>().getJobById(widget.jobId);
      setState(() { _job = job; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _onApplyMethod(String method) {
    Navigator.of(context).pushNamed('/apply', arguments: {
      'jobId': _job!.jobId,
      'jobTitle': _job!.title,
      'employerId': _job!.employerId,
      'applyMethod': method,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _job == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error ?? 'Job not found'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadJob, child: const Text('Retry')),
        ])),
      );
    }

    final job = _job!;
    final loc = context.read<LocationProvider>();
    final dist = loc.hasLocation
        ? context.read<JobProvider>().getDistanceToJob(job)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(job.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(job.employerName ?? 'Employer',
                    style: Theme.of(context).textTheme.titleMedium),
                if (job.employerVerified == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 16, color: AppTheme.primaryColor),
                ],
              ],
            ),
            const SizedBox(height: 4),
            if (job.employerRating != null)
              RatingWidget(rating: job.employerRating!, size: 18),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: Formatters.jobType(job.jobType), color: AppTheme.primaryColor),
                _Badge(label: '\$${job.payAmount.toStringAsFixed(0)}', color: AppTheme.successColor),
                if (dist != null)
                  _Badge(label: Formatters.distance(dist), color: AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 16),
            _Section(title: 'Schedule', content: job.schedule),
            _Section(title: 'Description', content: job.description),
            if (job.requiredSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Required Skills', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: job.requiredSkills.map((s) => Chip(label: Text(s))).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text('Location', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: SizedBox(
                height: 160,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(job.latitude, job.longitude),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('job'),
                      position: LatLng(job.latitude, job.longitude),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onApplyMethod('one-tap'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                  child: const Text('1-Tap', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onApplyMethod('resume'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: const Text('Resume', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onApplyMethod('chat'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: const Text('Chat First', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
