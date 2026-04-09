import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/job_card.dart';
import '../../widgets/quick_apply_modal.dart';
import '../../widgets/filter_bottom_sheet.dart';
import 'job_map_screen.dart';

class SeekerDashboard extends StatefulWidget {
  const SeekerDashboard({super.key});

  @override
  State<SeekerDashboard> createState() => _SeekerDashboardState();
}

class _SeekerDashboardState extends State<SeekerDashboard> {
  int _tab = 0;
  bool _mapView = false;
  final _searchCtrl = TextEditingController();
  String? _selectedType;

  static const _jobTypes = ['full-time', 'part-time', 'freelance', 'gig', 'shift-based'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    final loc = context.read<LocationProvider>();
    await loc.refreshLocation();
    if (!mounted) return;
    if (loc.hasLocation) {
      await context.read<JobProvider>().fetchNearbyJobs(
            lat: loc.latitude!,
            lon: loc.longitude!,
            refresh: true,
          );
      loc.startLocationStream((lat, lon) {
        if (mounted) {
          context.read<JobProvider>().fetchNearbyJobs(lat: lat, lon: lon, refresh: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    context.read<LocationProvider>().stopLocationStream();
    super.dispose();
  }

  Widget _buildHomeTab() {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocationProvider>();
    final jobs = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, ${(auth.user?.fullName ?? 'there').split(' ').first} 👋',
                style: const TextStyle(fontSize: 16)),
            if (loc.address.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: Colors.white70),
                const SizedBox(width: 2),
                Text(loc.address,
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => FilterBottomSheet.show(
              context,
              initialRadius: jobs.radiusKm,
              initialJobType: jobs.filterJobType,
              initialMinPay: jobs.filterMinPay,
              initialMaxPay: jobs.filterMaxPay,
              onApply: ({required radius, jobType, minPay, maxPay}) {
                jobs.setRadius(radius);
                jobs.applyFilters(jobType: jobType, minPay: minPay, maxPay: maxPay);
                if (loc.hasLocation) {
                  jobs.fetchNearbyJobs(lat: loc.latitude!, lon: loc.longitude!, refresh: true);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: jobs.setSearchQuery,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedType == null,
                  onSelected: (_) {
                    setState(() => _selectedType = null);
                    jobs.applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                ..._jobTypes.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t),
                        selected: _selectedType == t,
                        onSelected: (sel) {
                          setState(() => _selectedType = sel ? t : null);
                          jobs.applyFilters(jobType: sel ? t : null);
                        },
                      ),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${jobs.jobs.length} jobs nearby',
                    style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.list, size: 18)),
                    ButtonSegment(value: true, icon: Icon(Icons.map_outlined, size: 18)),
                  ],
                  selected: {_mapView},
                  onSelectionChanged: (s) => setState(() => _mapView = s.first),
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(const Size(0, 32)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _mapView
                ? const JobMapScreen()
                : _JobListView(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeTab(),
      const JobMapScreen(),
      _ApplicationsTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _JobListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>();
    final loc = context.watch<LocationProvider>();

    if (jobs.isLoading && jobs.jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (jobs.error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(jobs.error!),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (loc.hasLocation) {
                context.read<JobProvider>().fetchNearbyJobs(
                    lat: loc.latitude!, lon: loc.longitude!, refresh: true);
              }
            },
            child: const Text('Retry'),
          ),
        ]),
      );
    }
    if (jobs.jobs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('No jobs found nearby.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Try expanding your radius.',
              style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<JobProvider>().fetchNearbyJobs(
            lat: loc.latitude ?? 0,
            lon: loc.longitude ?? 0,
            refresh: true,
          ),
      child: ListView.builder(
        itemCount: jobs.jobs.length + (jobs.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == jobs.jobs.length) {
            if (!jobs.isLoading && loc.hasLocation) {
              context.read<JobProvider>().fetchNearbyJobs(
                    lat: loc.latitude!,
                    lon: loc.longitude!,
                  );
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final job = jobs.jobs[i];
          final dist = jobs.getDistanceToJob(job);
          return JobCard(
            job: job,
            distanceKm: dist,
            onTap: () => Navigator.of(context)
                .pushNamed('/job-detail', arguments: {'jobId': job.jobId}),
            onQuickApply: () => QuickApplyModal.show(context, (method) {
              Navigator.of(context).pushNamed('/apply', arguments: {
                'jobId': job.jobId,
                'jobTitle': job.title,
                'employerId': job.employerId,
                'applyMethod': method,
              });
            }),
          );
        },
      ),
    );
  }
}

class _ApplicationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/application-status');
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
