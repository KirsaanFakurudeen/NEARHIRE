import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_listing.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _tab = 0;
  int _totalApplications = 0;
  int _totalHires = 0;
  bool _statsLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _statsLoading = true);
    final userId = context.read<AuthProvider>().user?.userId ?? '';
    await context.read<JobProvider>().fetchEmployerJobs(userId);
    try {
      final db = FirebaseFirestore.instance;
      // Get all job IDs for this employer
      final jobSnap = await db
          .collection('jobs')
          .where('employerId', isEqualTo: userId)
          .get();
      final jobIds = jobSnap.docs.map((d) => d.id).toList();
      if (jobIds.isNotEmpty) {
        // Firestore 'whereIn' supports up to 30 items
        final appSnap = await db
            .collection('applications')
            .where('jobId', whereIn: jobIds.take(30).toList())
            .get();
        setState(() {
          _totalApplications = appSnap.docs.length;
          _totalHires = appSnap.docs
              .where((d) => d.data()['status'] == 'hired')
              .length;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _statsLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardHome(
        statsLoading: _statsLoading,
        totalApplications: _totalApplications,
        totalHires: _totalHires,
        onRefresh: _load,
      ),
      const _ListingsTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: pages[_tab],
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed('/post-job'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'My Listings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final bool statsLoading;
  final int totalApplications;
  final int totalHires;
  final VoidCallback onRefresh;

  const _DashboardHome({
    required this.statsLoading,
    required this.totalApplications,
    required this.totalHires,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final jobs = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NearHire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          children: [
            Text(
              'Hello, ${auth.user?.fullName ?? 'Employer'} 👋',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 4),
            Text('Here\'s your hiring overview',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            statsLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      _StatCard(
                        label: 'Active Jobs',
                        value: '${jobs.jobs.where((j) => j.status == 'active').length}',
                        icon: Icons.work_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Applications',
                        value: '$totalApplications',
                        icon: Icons.assignment_outlined,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Hires',
                        value: '$totalHires',
                        icon: Icons.check_circle_outline,
                        color: AppTheme.successColor,
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            Text('Recent Listings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (jobs.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (jobs.jobs.isEmpty)
              const Center(child: Text('No listings yet. Tap + to post a job.'))
            else
              ...jobs.jobs.take(5).map((job) => _JobSummaryCard(job: job)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  final JobListing job;
  const _JobSummaryCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(job.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(Formatters.jobType(job.jobType)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: job.status == 'active'
                ? AppTheme.successColor.withValues(alpha: 0.12)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            job.status == 'active' ? 'Active' : 'Closed',
            style: TextStyle(
              color: job.status == 'active' ? AppTheme.successColor : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => Navigator.of(context).pushNamed('/view-applications',
            arguments: {'jobId': job.jobId, 'jobTitle': job.title}),
      ),
    );
  }
}

class _ListingsTab extends StatelessWidget {
  const _ListingsTab();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/manage-listings');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/profile');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
