import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _api = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final res = await _api.get('/notifications/${auth.user?.userId}');
      final List data = res.data['notifications'] ?? [];
      setState(() => _notifications = data.map((n) => NotificationModel.fromJson(n)).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(NotificationModel notif) async {
    try {
      await _api.patch('/notifications/${notif.notifId}/read');
      setState(() {
        final idx = _notifications.indexWhere((n) => n.notifId == notif.notifId);
        if (idx != -1) {
          _notifications[idx] = NotificationModel.fromJson({
            ...notif.toJson(), 'isRead': true,
          });
        }
      });
      _navigate(notif);
    } catch (_) {}
  }

  void _navigate(NotificationModel notif) {
    switch (notif.type) {
      case 'job':
        Navigator.of(context).pushNamed('/job-detail', arguments: {'jobId': notif.referenceId});
        break;
      case 'application':
        Navigator.of(context).pushNamed('/application-status');
        break;
      case 'message':
        Navigator.of(context).pushNamed('/chat', arguments: {'applicationId': notif.referenceId, 'otherUserId': '', 'otherUserName': '', 'otherUserRole': ''});
        break;
      case 'interview':
        Navigator.of(context).pushNamed('/application-status');
        break;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'job': return Icons.work_outline;
      case 'application': return Icons.assignment_outlined;
      case 'message': return Icons.chat_bubble_outline;
      case 'interview': return Icons.calendar_today_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'job': return AppTheme.primaryColor;
      case 'application': return AppTheme.successColor;
      case 'message': return AppTheme.accentColor;
      case 'interview': return Colors.purple;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchNotifications, child: const Text('Retry')),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications yet'))
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final notif = _notifications[i];
                          final color = _colorForType(notif.type);
                          return InkWell(
                            onTap: () => _markRead(notif),
                            child: Container(
                              decoration: BoxDecoration(
                                color: notif.isRead ? null : color.withValues(alpha: 0.04),
                                border: notif.isRead
                                    ? null
                                    : Border(left: BorderSide(color: color, width: 4)),
                              ),
                              padding: const EdgeInsets.all(AppTheme.paddingM),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_iconForType(notif.type), color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(notif.title,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(notif.body, style: Theme.of(context).textTheme.bodyMedium),
                                        const SizedBox(height: 4),
                                        Text(Formatters.relativeTime(notif.createdAt),
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
