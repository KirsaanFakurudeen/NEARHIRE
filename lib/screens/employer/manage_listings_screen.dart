import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/job_listing.dart';

class ManageListingsScreen extends StatefulWidget {
  const ManageListingsScreen({super.key});

  @override
  State<ManageListingsScreen> createState() => _ManageListingsScreenState();
}

class _ManageListingsScreenState extends State<ManageListingsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<JobProvider>().fetchEmployerJobs(auth.user?.userId ?? '');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _closeJob(BuildContext context, String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Close Job'),
        content: const Text('Are you sure you want to close this listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await context.read<JobProvider>().closeJob(jobId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search listings...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: context.read<JobProvider>().setSearchQuery,
            ),
          ),
          Expanded(
            child: Consumer<JobProvider>(
              builder: (_, jobs, __) {
                if (jobs.isLoading) return const Center(child: CircularProgressIndicator());
                if (jobs.error != null) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(jobs.error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<JobProvider>()
                            .fetchEmployerJobs(context.read<AuthProvider>().user?.userId ?? ''),
                        child: const Text('Retry'),
                      ),
                    ]),
                  );
                }
                if (jobs.jobs.isEmpty) {
                  return const Center(child: Text('No listings found.'));
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<JobProvider>()
                      .fetchEmployerJobs(context.read<AuthProvider>().user?.userId ?? ''),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
                    itemCount: jobs.jobs.length,
                    itemBuilder: (_, i) => _ListingCard(
                      job: jobs.jobs[i],
                      onViewApplications: () => Navigator.of(context).pushNamed(
                        '/view-applications',
                        arguments: {'jobId': jobs.jobs[i].jobId, 'jobTitle': jobs.jobs[i].title},
                      ),
                      onClose: () => _closeJob(context, jobs.jobs[i].jobId),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final JobListing job;
  final VoidCallback onViewApplications;
  final VoidCallback onClose;

  const _ListingCard({required this.job, required this.onViewApplications, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isActive = job.status == 'active';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onViewApplications,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.successColor.withValues(alpha: 0.12) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Closed',
                      style: TextStyle(
                        color: isActive ? AppTheme.successColor : AppTheme.textSecondary,
                        fontSize: 11, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(Formatters.jobType(job.jobType),
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('\$${job.payAmount.toStringAsFixed(0)} • Posted ${Formatters.date(job.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/post-job'),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.errorColor),
                    onPressed: onClose,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
