import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.customer; // Default role

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    LoggerService.info('Register screen initialized', tag: 'RegisterScreen');
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Please accept the Terms of Service and Privacy Policy';
      });
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();

    try {
      LoggerService.info(
          'Attempting registration for: $email as ${_selectedRole.toString()}',
          tag: 'RegisterScreen');

      final success = await authProvider.register(
        email: email,
        password: password,
        name: name,
        phoneNumber: phone,
        role: _selectedRole,
        additionalData: {
          'registrationSource': 'mobile_app',
          'acceptedTerms': true,
          'acceptedPrivacy': true,
          'registrationDate': DateTime.now().toIso8601String(),
        },
      );

      if (success && mounted) {
        LoggerService.info('Registration successful for: $email',
            tag: 'RegisterScreen');

        // Show success feedback
        _showSuccessSnackBar();

        // Navigate to customer home
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.customerHome,
          (route) => false,
        );
      } else if (mounted) {
        setState(() {
          _errorMessage =
              authProvider.error ?? 'Registration failed. Please try again.';
        });
        LoggerService.warning('Registration failed: $_errorMessage',
            tag: 'RegisterScreen');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
        LoggerService.error('Registration error',
            error: e, tag: 'RegisterScreen');
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Welcome to Fresh Marikiti! Registration successful.'),
          ],
        ),
        backgroundColor: context.colors.freshGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name should only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces, dashes, or parentheses
    String cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with + for international or is all digits
    if (cleanPhone.startsWith('+')) {
      if (cleanPhone.length < 10 || cleanPhone.length > 15) {
        return 'Please enter a valid phone number';
      }
    } else if (RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      if (cleanPhone.length < 10) {
        return 'Phone number must be at least 10 digits';
      }
    } else {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: context.colors.textPrimary,
              ),
              onPressed: _navigateToLogin,
            ),
          ),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildHeader(),

                      const SizedBox(height: AppSpacing.xl),

                      // User Type Selector
                      _buildUserTypeSelector(),

                      const SizedBox(height: AppSpacing.lg),

                      // Registration Form
                      _buildRegistrationForm(authProvider),

                      const SizedBox(height: AppSpacing.lg),

                      // Terms and Conditions
                      _buildTermsAcceptance(),

                      const SizedBox(height: AppSpacing.lg),

                      // Error Message
                      if (_errorMessage != null) _buildErrorMessage(),

                      const SizedBox(height: AppSpacing.lg),

                      // Register Button
                      _buildRegisterButton(authProvider),

                      const SizedBox(height: AppSpacing.xl),

                      // Login Link
                      _buildLoginLink(),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: context.colors.freshGreen,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: const Icon(
            Icons.person_add,
            size: 35,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Welcome Text
        Text(
          'Join Fresh Marikiti',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          'Create your customer account to start ordering fresh produce from local markets',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Account Type',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceColor.withOpacity(0.5),
            borderRadius: AppRadius.radiusLG,
            border: Border.all(
              color: context.colors.textSecondary.withOpacity(0.3),
            ),
          ),
          child: SegmentedButton<UserRole>(
            segments: const [
              ButtonSegment<UserRole>(
                value: UserRole.customer,
                label: Text('Customer'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment<UserRole>(
                value: UserRole.vendor,
                label: Text('Vendor'),
                icon: Icon(Icons.store_outlined),
              ),
              ButtonSegment<UserRole>(
                value: UserRole.rider,
                label: Text('Rider'),
                icon: Icon(Icons.delivery_dining_outlined),
              ),
              ButtonSegment<UserRole>(
                value: UserRole.connector,
                label: Text('Connector'),
                icon: Icon(Icons.recycling_outlined),
              ),
              ButtonSegment<UserRole>(
                value: UserRole.vendorAdmin,
                label: Text('Vendor Admin'),
                icon: Icon(Icons.admin_panel_settings_outlined),
              ),
            ],
            selected: {_selectedRole},
            onSelectionChanged: (Set<UserRole> selected) {
              setState(() {
                _selectedRole = selected.first;
              });
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return context.colors.freshGreen;
                  }
                  return context.colors.surfaceColor;
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return context.colors.textPrimary;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name Field
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: _validateName,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: context.colors.freshGreen,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.textSecondary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.freshGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: context.colors.surfaceColor.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: context.colors.freshGreen,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.textSecondary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.freshGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: context.colors.surfaceColor.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: _validatePhone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: context.colors.freshGreen,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.textSecondary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.freshGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: context.colors.surfaceColor.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a strong password',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: context.colors.freshGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.colors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.textSecondary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.freshGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: context.colors.surfaceColor.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            validator: _validateConfirmPassword,
            onFieldSubmitted: (_) => _handleRegister(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: context.colors.freshGreen,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.colors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.textSecondary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusLG,
                borderSide: BorderSide(
                  color: context.colors.freshGreen,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: context.colors.surfaceColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAcceptance() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: context.colors.freshGreen,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: RichText(
              text: TextSpan(
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' of Fresh Marikiti'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: AppRadius.radiusLG,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.freshGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusLG,
          ),
          elevation: 4,
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Create Customer Account',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: _navigateToLogin,
          child: Text(
            'Sign In',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.freshGreen,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: context.colors.freshGreen,
            ),
          ),
        ),
      ],
    );
  }
}
