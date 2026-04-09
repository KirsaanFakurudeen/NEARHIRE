import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/app_theme.dart';
import '../../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(
        emailOrPhone: _contactCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        dashboardRouteForRole(auth.role),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _loginWithOtp() {
    Navigator.of(context).pushNamed('/otp', arguments: {
      'userId': '',
      'contact': _contactCtrl.text.trim(),
      'isLoginFlow': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    Text('Welcome back',
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 8),
                    Text('Sign in to find jobs near you',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _contactCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email or Phone',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.emailOrPhone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isLoading ? null : _loginWithOtp,
                      child: const Text('Login with OTP'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?",
                            style: Theme.of(context).textTheme.bodyMedium),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/register'),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '— UI Testing —',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.business_center, size: 18),
                            label: const Text('Employer UI'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () async {
                              await context
                                  .read<AuthProvider>()
                                  .devSkipLogin('employer');
                              if (!mounted) return;
                              Navigator.of(context)
                                  .pushReplacementNamed('/employer-dashboard');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.person_search, size: 18),
                            label: const Text('Seeker UI'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentColor,
                              side: const BorderSide(color: AppTheme.accentColor),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () async {
                              await context
                                  .read<AuthProvider>()
                                  .devSkipLogin('seeker');
                              if (!mounted) return;
                              Navigator.of(context)
                                  .pushReplacementNamed('/seeker-dashboard');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
