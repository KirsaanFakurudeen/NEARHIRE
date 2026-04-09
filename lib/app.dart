import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';

// Auth
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/role_selection_screen.dart';

// Employer
import 'screens/employer/employer_dashboard.dart';
import 'screens/employer/post_job_screen.dart';
import 'screens/employer/manage_listings_screen.dart';
import 'screens/employer/view_applications_screen.dart';
import 'screens/employer/applicant_profile_screen.dart';
import 'screens/employer/hire_close_job_screen.dart';

// Seeker
import 'screens/seeker/seeker_dashboard.dart';
import 'screens/seeker/job_detail_screen.dart';
import 'screens/seeker/apply_screen.dart';
import 'screens/seeker/application_status_screen.dart';

// Shared
import 'screens/shared/chat_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/shared/notification_screen.dart';
import 'screens/shared/rating_screen.dart';
import 'screens/shared/report_screen.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearHire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      onGenerateRoute: (settings) => _generateRoute(settings, context),
    );
  }

  Route<dynamic>? _generateRoute(
      RouteSettings settings, BuildContext context) {
    final authRoutes = {'/splash', '/login', '/register', '/otp', '/role-selection'};

    Widget page;
    switch (settings.name) {
      case '/splash':
        page = const SplashScreen();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/register':
        page = const RegisterScreen();
        break;
      case '/otp':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = OtpScreen(
          userId: args['userId'] ?? '',
          contact: args['contact'] ?? '',
          isLoginFlow: args['isLoginFlow'] ?? false,
        );
        break;
      case '/role-selection':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = RoleSelectionScreen(userId: args['userId'] ?? '');
        break;
      case '/employer-dashboard':
        page = const EmployerDashboard();
        break;
      case '/post-job':
        page = const PostJobScreen();
        break;
      case '/manage-listings':
        page = const ManageListingsScreen();
        break;
      case '/view-applications':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = ViewApplicationsScreen(
          jobId: args['jobId'] ?? '',
          jobTitle: args['jobTitle'] ?? '',
        );
        break;
      case '/applicant-profile':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = ApplicantProfileScreen(
          applicationId: args['applicationId'] ?? '',
          seekerId: args['seekerId'] ?? '',
        );
        break;
      case '/hire-close-job':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = HireCloseJobScreen(
          jobId: args['jobId'] ?? '',
          jobTitle: args['jobTitle'] ?? '',
          seekerId: args['seekerId'] ?? '',
          seekerName: args['seekerName'] ?? '',
          applicationId: args['applicationId'] ?? '',
        );
        break;
      case '/seeker-dashboard':
        page = const SeekerDashboard();
        break;
      case '/job-detail':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = JobDetailScreen(jobId: args['jobId'] ?? '');
        break;
      case '/apply':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = ApplyScreen(
          jobId: args['jobId'] ?? '',
          jobTitle: args['jobTitle'] ?? '',
          employerId: args['employerId'] ?? '',
          applyMethod: args['applyMethod'] ?? 'one-tap',
        );
        break;
      case '/application-status':
        page = const ApplicationStatusScreen();
        break;
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = ChatScreen(
          applicationId: args['applicationId'] ?? '',
          otherUserId: args['otherUserId'] ?? '',
          otherUserName: args['otherUserName'] ?? '',
          otherUserRole: args['otherUserRole'] ?? '',
        );
        break;
      case '/profile':
        page = const ProfileScreen();
        break;
      case '/notifications':
        page = const NotificationScreen();
        break;
      case '/rating':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = RatingScreen(
          jobId: args['jobId'] ?? '',
          ratedUserId: args['ratedUserId'] ?? '',
          ratedUserName: args['ratedUserName'] ?? '',
        );
        break;
      case '/report':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        page = ReportScreen(
          targetId: args['targetId'] ?? '',
          targetType: args['targetType'] ?? 'user',
        );
        break;
      default:
        page = const LoginScreen();
    }

    // Route guard
    if (!authRoutes.contains(settings.name)) {
      return MaterialPageRoute(
        builder: (_) => _AuthGuard(child: page),
        settings: settings,
      );
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class _AuthGuard extends StatelessWidget {
  final Widget child;
  const _AuthGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return child;
  }
}

String dashboardRouteForRole(String role) {
  return role == AppConstants.roleEmployer
      ? '/employer-dashboard'
      : '/seeker-dashboard';
}
