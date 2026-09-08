import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Login Screen - Cleaned Spacing
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isPasswordVisible = false;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Espace supérieur contrôlé
              const SizedBox(height: 30),

              // Logo réajusté
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/icons/ferme-logo.png',
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // Error message (Provider)
              Consumer<AuthNotifier>(
                builder: (context, authNotifier, child) {
                  if (authNotifier.error == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      border: const Border(
                        left: BorderSide(color: AppColors.danger, width: 4),
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
                  );
                },
              ),
              const SizedBox(height: 20),

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
                obscureText: !_isPasswordVisible,
                suffix: GestureDetector(
                  onTap: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
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
              Consumer<AuthNotifier>(
                builder: (context, authNotifier, child) {
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context, String? role) {
    // TODO: Routing d'accueil selon le rôle
  }
}

/// Splash Screen mis à jour avec le logo image
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
    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icons/ferme-logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppConstants.appName,
              style: AppTypography.h2.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
