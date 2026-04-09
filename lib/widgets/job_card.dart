import 'package:flutter/material.dart';
import '../models/job_listing.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class JobCard extends StatelessWidget {
  final JobListing job;
  final double distanceKm;
  final VoidCallback onTap;
  final VoidCallback onQuickApply;

  const JobCard({
    super.key,
    required this.job,
    required this.distanceKm,
    required this.onTap,
    required this.onQuickApply,
  });

  Color _jobTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'full-time': return const Color(0xFF1565C0);
      case 'part-time': return const Color(0xFF6A1B9A);
      case 'freelance': return const Color(0xFF2E7D32);
      case 'gig': return const Color(0xFFE65100);
      case 'shift-based': return const Color(0xFF00695C);
      default: return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _jobTypeColor(job.jobType).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Formatters.jobType(job.jobType),
                      style: TextStyle(
                        color: _jobTypeColor(job.jobType),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                job.employerName ?? 'Employer',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: AppTheme.successColor),
                  Text(
                    Formatters.currencyCompact(job.payAmount),
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                  Text(
                    Formatters.distance(distanceKm),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onQuickApply,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    child: const Text('Quick Apply', style: TextStyle(fontSize: 12)),
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
