import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show CircleMarker;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/job_listing.dart';

class JobFlutterMapScreen extends StatefulWidget {
  const JobFlutterMapScreen({super.key});

  @override
  State<JobFlutterMapScreen> createState() => _JobFlutterMapScreenState();
}

class _JobFlutterMapScreenState extends State<JobFlutterMapScreen> {
  final MapController _mapController = MapController();
  JobListing? _selectedJob;
  double _radius = AppConstants.defaultRadiusKm;

  void _onRadiusChanged(double val) {
    setState(() => _radius = val);
    // Just update radius and re-filter locally — no need to re-fetch from Firestore
    context.read<JobProvider>().setRadius(val);
    context.read<JobProvider>().applyFilters(
      jobType: context.read<JobProvider>().filterJobType,
      minPay: context.read<JobProvider>().filterMinPay,
      maxPay: context.read<JobProvider>().filterMaxPay,
    );
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'full-time':
        return const Color(0xFF1565C0);
      case 'part-time':
        return const Color(0xFF6A1B9A);
      case 'freelance':
        return const Color(0xFF2E7D32);
      case 'gig':
        return const Color(0xFFE65100);
      case 'shift-based':
        return const Color(0xFF00695C);
      default:
        return const Color(0xFF1A3C6E);
    }
  }

  String _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'full-time':
        return '💼';
      case 'part-time':
        return '⏰';
      case 'freelance':
        return '💻';
      case 'gig':
        return '⚡';
      case 'shift-based':
        return '🔄';
      default:
        return '📍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final jobProvider = context.watch<JobProvider>();

    if (!loc.hasLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    final userLatLng = LatLng(loc.latitude!, loc.longitude!);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLatLng,
            initialZoom: 13,
            onTap: (_, __) => setState(() => _selectedJob = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nearhire.app',
            ),
            // Radius circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: userLatLng,
                  radius: _radius * 1000, // convert km to meters
                  useRadiusInMeter: true,
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // User location marker
                Marker(
                  point: userLatLng,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                ),
                // Job markers
                ...jobProvider.jobs.map((job) => Marker(
                      point: LatLng(job.latitude, job.longitude),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedJob = job),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _colorForType(job.jobType),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Text(_iconForType(job.jobType),
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ],
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
        if (jobProvider.isLoading)
          const Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
        // Job bottom card
        if (_selectedJob != null)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: _JobMapCard(
              job: _selectedJob!,
              distanceKm: jobProvider.getDistanceToJob(_selectedJob!),
              onViewDetails: () => Navigator.of(context).pushNamed(
                '/job-detail',
                arguments: {'jobId': _selectedJob!.jobId},
              ),
            ),
          ),
        // OSM attribution (required by OpenStreetMap license)
        const Positioned(
          bottom: 4,
          right: 8,
          child: Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 10, color: Colors.black54),
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

  const _JobMapCard(
      {required this.job, required this.distanceKm, required this.onViewDetails});

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
                    style: const TextStyle(
                        color: AppTheme.successColor, fontWeight: FontWeight.w600)),
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
