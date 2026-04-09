import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';

class FilterBottomSheet extends StatefulWidget {
  final double initialRadius;
  final String? initialJobType;
  final double? initialMinPay;
  final double? initialMaxPay;
  final void Function({
    required double radius,
    String? jobType,
    double? minPay,
    double? maxPay,
  }) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialRadius,
    this.initialJobType,
    this.initialMinPay,
    this.initialMaxPay,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required double initialRadius,
    String? initialJobType,
    double? initialMinPay,
    double? initialMaxPay,
    required void Function({
      required double radius,
      String? jobType,
      double? minPay,
      double? maxPay,
    }) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (_) => FilterBottomSheet(
        initialRadius: initialRadius,
        initialJobType: initialJobType,
        initialMinPay: initialMinPay,
        initialMaxPay: initialMaxPay,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late double _radius;
  String? _jobType;
  RangeValues _payRange = const RangeValues(0, 5000);

  static const _jobTypes = ['full-time', 'part-time', 'freelance', 'gig', 'shift-based'];

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
    _jobType = widget.initialJobType;
    _payRange = RangeValues(
      widget.initialMinPay ?? 0,
      widget.initialMaxPay ?? 5000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter Jobs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Text('Search Radius: ${_radius.toStringAsFixed(0)} km',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _radius,
              min: AppConstants.minRadiusKm,
              max: AppConstants.maxRadiusKm,
              divisions: 49,
              label: '${_radius.toStringAsFixed(0)} km',
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 16),
            Text('Job Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _jobTypes.map((type) => FilterChip(
                label: Text(type),
                selected: _jobType == type,
                onSelected: (sel) =>
                    setState(() => _jobType = sel ? type : null),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Pay Range: \$${_payRange.start.toStringAsFixed(0)} - \$${_payRange.end.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RangeSlider(
              values: _payRange,
              min: 0,
              max: 10000,
              divisions: 100,
              labels: RangeLabels(
                '\$${_payRange.start.toStringAsFixed(0)}',
                '\$${_payRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (v) => setState(() => _payRange = v),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(
                  radius: _radius,
                  jobType: _jobType,
                  minPay: _payRange.start > 0 ? _payRange.start : null,
                  maxPay: _payRange.end < 10000 ? _payRange.end : null,
                );
              },
              child: const Text('Apply Filters'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(
                  radius: AppConstants.defaultRadiusKm,
                  jobType: null,
                  minPay: null,
                  maxPay: null,
                );
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
