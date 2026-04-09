import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/application.dart';

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<ApplicationProvider>().fetchApplicationsForSeeker(auth.user?.userId ?? '');
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppTheme.successColor;
      case 'rejected': return AppTheme.errorColor;
      case 'interview_scheduled': return Colors.blue;
      case 'hired': return Colors.purple;
      default: return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      case 'interview_scheduled': return 'Interview Scheduled';
      case 'hired': return 'Hired';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
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
                      .fetchApplicationsForSeeker(context.read<AuthProvider>().user?.userId ?? ''),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          if (apps.applications.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }
          return RefreshIndicator(
            onRefresh: () => context.read<ApplicationProvider>()
                .fetchApplicationsForSeeker(context.read<AuthProvider>().user?.userId ?? ''),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: apps.applications.length,
              itemBuilder: (_, i) {
                final app = apps.applications[i];
                final statusColor = _statusColor(app.status);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    onTap: (app.status == 'accepted' || app.status == 'interview_scheduled')
                        ? () => _showDetails(context, app)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(app.jobTitle ?? 'Job',
                                    style: Theme.of(context).textTheme.titleMedium),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(app.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(app.employerName ?? '',
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
                                child: Text(app.applyMethod.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Text(Formatters.relativeTime(app.appliedAt),
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          if (app.status == 'interview_scheduled' &&
                              app.interviewScheduledAt != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Interview: ${Formatters.dateTime(app.interviewScheduledAt!)}',
                                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, Application app) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.jobTitle ?? 'Job', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (app.interviewScheduledAt != null)
              Text('Interview: ${Formatters.dateTime(app.interviewScheduledAt!)}',
                  style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open Chat'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/chat', arguments: {
                  'applicationId': app.applicationId,
                  'otherUserId': app.seekerId,
                  'otherUserName': app.employerName ?? 'Employer',
                  'otherUserRole': 'Employer',
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
