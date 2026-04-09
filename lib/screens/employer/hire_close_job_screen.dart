import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../screens/shared/rating_screen.dart';

class HireCloseJobScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String seekerId;
  final String seekerName;
  final String applicationId;

  const HireCloseJobScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.seekerId,
    required this.seekerName,
    required this.applicationId,
  });

  @override
  State<HireCloseJobScreen> createState() => _HireCloseJobScreenState();
}

class _HireCloseJobScreenState extends State<HireCloseJobScreen> {
  bool _isLoading = false;

  Future<void> _confirmHire() async {
    setState(() => _isLoading = true);
    try {
      await context.read<ApplicationProvider>().updateApplicationStatus(
            widget.applicationId,
            'hired',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hire confirmed! Job closed.')),
      );
      await RatingScreen.show(
        context,
        jobId: widget.jobId,
        ratedUserId: widget.seekerId,
        ratedUserName: widget.seekerName,
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.settings.name == '/employer-dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Hire')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 64, color: AppTheme.successColor),
            ),
            const SizedBox(height: 24),
            Text('Confirm Hire', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingL),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Job', value: widget.jobTitle),
                    const Divider(),
                    _SummaryRow(label: 'Candidate', value: widget.seekerName),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will mark the application as hired and close the job listing.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmHire,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Hire'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
