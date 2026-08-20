import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Login Screen - Faithful to mockups
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isPasswordVisible = false;
  final bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        AppConstants.appName,
                        style: AppTypography.h2.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Username Field
                      AppInputBox(
                        label: 'Identifiant',
                        placeholder: 'Nom d\'utilisateur',
                        controller: _usernameController,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      AppInputBox(
                        label: 'Mot de passe',
                        placeholder: '••••••••',
                        controller: _passwordController,
                        inputType: TextInputType.visiblePassword,
                        suffix: GestureDetector(
                          onTap: () {
                            setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            );
                          },
                          child: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      Builder(
                        builder: (context) {
                          final authNotifier = Provider.of<AuthNotifier>(
                            context,
                          );
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authNotifier.isLoading
                                  ? null
                                  : () async {
                                      final success = await authNotifier.login(
                                        _usernameController.text,
                                        _passwordController.text,
                                      );
                                      if (success && mounted) {
                                        _navigateToHome(
                                          context,
                                          authNotifier.currentUser?.role,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: authNotifier.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 18.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),

                      // Error message
                      Builder(
                        builder: (context) {
                          final authNotifier = Provider.of<AuthNotifier>(
                            context,
                          );
                          if (authNotifier.error != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  border: const Border(
                                    left: BorderSide(
                                      color: AppColors.danger,
                                      width: 4,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  authNotifier.error!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 24),

                      // Offline Note
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(
                              Icons.info_outlined,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Une fois connecté, l\'application reste utilisable sans connexion Internet.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context, String? role) {
    // TODO: Implement navigation based on role
    // This will be handled by the app routing system
  }
}

/// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize auth and check login status
    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.init();

    if (mounted) {
      if (authNotifier.isLoggedIn) {
        // Navigate to home screen based on role
        // _navigateToHome(authNotifier.currentUser?.role);
      } else {
        // Navigate to login
        // _navigateToLogin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.home, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              AppConstants.appName,
              style: AppTypography.h2.copyWith(fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }
}
