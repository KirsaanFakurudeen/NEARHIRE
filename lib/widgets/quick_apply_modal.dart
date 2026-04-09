import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class QuickApplyModal extends StatelessWidget {
  final ValueChanged<String> onMethodSelected;

  const QuickApplyModal({super.key, required this.onMethodSelected});

  static Future<void> show(
    BuildContext context,
    ValueChanged<String> onMethodSelected,
  ) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (_) => QuickApplyModal(onMethodSelected: onMethodSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('How would you like to apply?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _ApplyOption(
            icon: Icons.bolt,
            color: AppTheme.accentColor,
            label: 'One-Tap Apply',
            subtitle: 'Apply instantly with your profile',
            onTap: () {
              Navigator.pop(context);
              onMethodSelected('one-tap');
            },
          ),
          const SizedBox(height: 12),
          _ApplyOption(
            icon: Icons.description_outlined,
            color: AppTheme.primaryColor,
            label: 'Upload Resume',
            subtitle: 'Attach your PDF resume',
            onTap: () {
              Navigator.pop(context);
              onMethodSelected('resume');
            },
          ),
          const SizedBox(height: 12),
          _ApplyOption(
            icon: Icons.chat_bubble_outline,
            color: AppTheme.successColor,
            label: 'Chat First',
            subtitle: 'Message the employer before applying',
            onTap: () {
              Navigator.pop(context);
              onMethodSelected('chat');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ApplyOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ApplyOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
