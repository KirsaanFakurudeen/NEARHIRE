import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/rating_widget.dart';

class RatingScreen extends StatefulWidget {
  final String jobId;
  final String ratedUserId;
  final String ratedUserName;

  const RatingScreen({
    super.key,
    required this.jobId,
    required this.ratedUserId,
    required this.ratedUserName,
  });

  static Future<void> show(
    BuildContext context, {
    required String jobId,
    required String ratedUserId,
    required String ratedUserName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (_) => RatingScreen(
        jobId: jobId,
        ratedUserId: ratedUserId,
        ratedUserName: ratedUserName,
      ),
    );
  }

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final ApiService _api = ApiService();
  final _reviewCtrl = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _api.post('/ratings', data: {
        'jobId': widget.jobId,
        'ratedUser': widget.ratedUserId,
        'score': _rating,
        'review': _reviewCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted!')),
      );
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
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.paddingL,
        right: AppTheme.paddingL,
        top: AppTheme.paddingL,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.paddingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Rate ${widget.ratedUserName}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          RatingWidget(
            rating: _rating,
            readOnly: false,
            size: 40,
            onRatingChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _reviewCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Write a review (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Rating'),
          ),
        ],
      ),
    );
  }
}
