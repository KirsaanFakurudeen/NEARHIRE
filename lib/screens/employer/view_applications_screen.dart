import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/application.dart';

class ViewApplicationsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const ViewApplicationsScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  State<ViewApplicationsScreen> createState() => _ViewApplicationsScreenState();
}

class _ViewApplicationsScreenState extends State<ViewApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicationProvider>().fetchApplicationsForJob(widget.jobId);
    });
  }

  Future<void> _updateStatus(String appId, String status) async {
    try {
      await context.read<ApplicationProvider>().updateApplicationStatus(appId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application ${status == 'accepted' ? 'accepted' : 'rejected'}')),
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
      appBar: AppBar(title: Text(widget.jobTitle)),
      body: Consumer<ApplicationProvider>(
        builder: (_, apps, __) {
          if (apps.isLoading) return const Center(child: CircularProgressIndicator());
          if (apps.error != null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(apps.error!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.read<ApplicationProvider>()
                      .fetchApplicationsForJob(widget.jobId),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          if (apps.applications.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingM),
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_outlined, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '${apps.applications.length} Application${apps.applications.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<ApplicationProvider>()
                      .fetchApplicationsForJob(widget.jobId),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    itemCount: apps.applications.length,
                    itemBuilder: (_, i) => _ApplicationCard(
                      app: apps.applications[i],
                      onAccept: () => _updateStatus(apps.applications[i].applicationId, 'accepted'),
                      onReject: () => _updateStatus(apps.applications[i].applicationId, 'rejected'),
                      onViewProfile: () => Navigator.of(context).pushNamed(
                        '/applicant-profile',
                        arguments: {
                          'applicationId': apps.applications[i].applicationId,
                          'seekerId': apps.applications[i].seekerId,
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Application app;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _ApplicationCard({
    required this.app,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppTheme.successColor;
      case 'rejected': return AppTheme.errorColor;
      case 'interview_scheduled': return Colors.blue;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(app.seekerName ?? 'Applicant',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(app.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      app.status.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(app.status),
                        fontSize: 10, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (app.seekerSkills != null && app.seekerSkills!.isNotEmpty)
                Text(app.seekerSkills!.join(', '),
                    style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      app.applyMethod.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(Formatters.relativeTime(app.appliedAt),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              if (app.status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Accept', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Reject', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
