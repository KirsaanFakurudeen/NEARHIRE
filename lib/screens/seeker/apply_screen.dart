import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ApplyScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String employerId;
  final String applyMethod;

  const ApplyScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.employerId,
    required this.applyMethod,
  });

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  bool _isLoading = false;
  bool _success = false;
  String? _resumeFilePath;
  String? _resumeFileName;

  @override
  void initState() {
    super.initState();
    if (widget.applyMethod == 'one-tap') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitOneTap());
    } else if (widget.applyMethod == 'chat') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitChatFirst());
    }
  }

  Future<void> _submitOneTap() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await context.read<ApplicationProvider>().submitApplication(
            jobId: widget.jobId,
            seekerId: auth.user?.userId ?? '',
            applyMethod: 'one-tap',
          );
      setState(() { _success = true; });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndSubmitResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    setState(() {
      _resumeFilePath = result.files.single.path;
      _resumeFileName = result.files.single.name;
    });
  }

  Future<void> _submitResume() async {
    if (_resumeFilePath == null) return;
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await context.read<ApplicationProvider>().submitApplicationWithResume(
            jobId: widget.jobId,
            seekerId: auth.user?.userId ?? '',
            filePath: _resumeFilePath!,
          );
      setState(() => _success = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitChatFirst() async {
    final auth = context.read<AuthProvider>();
    try {
      final app = await context.read<ApplicationProvider>().submitApplication(
            jobId: widget.jobId,
            seekerId: auth.user?.userId ?? '',
            applyMethod: 'chat',
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/chat', arguments: {
        'applicationId': app.applicationId,
        'otherUserId': widget.employerId,
        'otherUserName': 'Employer',
        'otherUserRole': 'Employer',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _SuccessView(jobTitle: widget.jobTitle);

    if (widget.applyMethod == 'one-tap') {
      return Scaffold(
        appBar: AppBar(title: const Text('Applying...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.applyMethod == 'chat') {
      return Scaffold(
        appBar: AppBar(title: const Text('Starting Chat...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Resume flow
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Resume')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Applying for', style: Theme.of(context).textTheme.bodyMedium),
                Text(widget.jobTitle, style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _pickAndSubmitResume,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _resumeFileName != null
                            ? AppTheme.successColor
                            : AppTheme.dividerColor,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _resumeFileName != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          size: 48,
                          color: _resumeFileName != null
                              ? AppTheme.successColor
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _resumeFileName ?? 'Tap to select PDF resume',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _resumeFilePath == null || _isLoading ? null : _submitResume,
                  child: const Text('Submit Application'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String jobTitle;
  const _SuccessView({required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 80, color: AppTheme.successColor),
              ),
              const SizedBox(height: 24),
              Text('Application Submitted!',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(jobTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/application-status',
                  (r) => r.settings.name == '/seeker-dashboard',
                ),
                child: const Text('View Application Status'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil(
                  (r) => r.settings.name == '/seeker-dashboard',
                ),
                child: const Text('Back to Jobs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
