import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/job_listing.dart';
import '../../widgets/map_job_marker.dart';

class JobMapScreen extends StatefulWidget {
  const JobMapScreen({super.key});

  @override
  State<JobMapScreen> createState() => _JobMapScreenState();
}

class _JobMapScreenState extends State<JobMapScreen> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  JobListing? _selectedJob;
  double _radius = AppConstants.defaultRadiusKm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildMarkers());
  }

  Future<void> _buildMarkers() async {
    final jobs = context.read<JobProvider>().jobs;
    final newMarkers = <MarkerId, Marker>{};
    for (final job in jobs) {
      final icon = await MapJobMarker.create(job.jobType);
      final id = MarkerId(job.jobId);
      newMarkers[id] = Marker(
        markerId: id,
        position: LatLng(job.latitude, job.longitude),
        icon: icon,
        onTap: () => setState(() => _selectedJob = job),
      );
    }
    if (mounted) setState(() => _markers.addAll(newMarkers));
  }

  void _onRadiusChanged(double val) {
    setState(() => _radius = val);
    final loc = context.read<LocationProvider>();
    context.read<JobProvider>().setRadius(val);
    if (loc.hasLocation) {
      context.read<JobProvider>().fetchNearbyJobs(
            lat: loc.latitude!,
            lon: loc.longitude!,
            refresh: true,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final jobs = context.watch<JobProvider>();

    if (!loc.hasLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    final userLatLng = LatLng(loc.latitude!, loc.longitude!);

    // Rebuild markers when jobs change
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildMarkers());

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: userLatLng, zoom: 13),
          onMapCreated: (c) => _mapController = c,
          markers: {
            Marker(
              markerId: const MarkerId('user'),
              position: userLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            ),
            ..._markers.values,
          },
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          onTap: (_) => setState(() => _selectedJob = null),
        ),
        // Radius slider
        Positioned(
          bottom: _selectedJob != null ? 220 : 80,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.radar, color: AppTheme.primaryColor),
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: AppConstants.minRadiusKm,
                      max: AppConstants.maxRadiusKm,
                      divisions: 49,
                      onChanged: _onRadiusChanged,
                    ),
                  ),
                  Text('${_radius.toStringAsFixed(0)} km',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
        if (jobs.isLoading)
          const Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
        // Job bottom sheet card
        if (_selectedJob != null)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: _JobMapCard(
              job: _selectedJob!,
              distanceKm: jobs.getDistanceToJob(_selectedJob!),
              onViewDetails: () => Navigator.of(context).pushNamed(
                '/job-detail',
                arguments: {'jobId': _selectedJob!.jobId},
              ),
            ),
          ),
      ],
    );
  }
}

class _JobMapCard extends StatelessWidget {
  final JobListing job;
  final double distanceKm;
  final VoidCallback onViewDetails;

  const _JobMapCard({required this.job, required this.distanceKm, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(job.employerName ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(Formatters.currencyCompact(job.payAmount),
                    style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                Text(Formatters.distance(distanceKm),
                    style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(100, 36)),
                  child: const Text('View Details', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
