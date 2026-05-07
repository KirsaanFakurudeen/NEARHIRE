import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

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
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RatingScreen(
        jobId: jobId,
        ratedUserId: ratedUserId,
        ratedUserName: ratedUserName,
      ),
    ));
  }

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _db = FirebaseFirestore.instance;
  final _feedbackCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_feedbackCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your feedback')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final raterId = context.read<AuthProvider>().user?.userId ?? '';
      await _db.collection('ratings').add({
        'jobId': widget.jobId,
        'ratedUserId': widget.ratedUserId,
        'raterId': raterId,
        'review': _feedbackCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
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
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback for ${widget.ratedUserName}')),
      body: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.paddingL,
          right: AppTheme.paddingL,
          top: AppTheme.paddingL,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.paddingL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('How was your experience with ${widget.ratedUserName}?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write your feedback here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
