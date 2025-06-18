import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    LoggerService.info('Forgot password screen initialized', tag: 'ForgotPasswordScreen');
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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      LoggerService.info('Attempting password reset for: $email', tag: 'ForgotPasswordScreen');
      
      // Note: This would integrate with AuthService's password reset functionality
      // For now, we'll simulate the API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful password reset request
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        
        LoggerService.info('Password reset email sent to: $email', tag: 'ForgotPasswordScreen');
        _showSuccessSnackBar();
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send reset email. Please try again.';
          _isLoading = false;
        });
        LoggerService.error('Password reset error', error: e, tag: 'ForgotPasswordScreen');
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
            const Text('Password reset instructions sent to your email'),
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

  void _resendEmail() {
    setState(() {
      _emailSent = false;
    });
    _handleResetPassword();
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

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Header
                      _buildHeader(),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Content based on state
                      if (!_emailSent) ...[
                        // Email input form
                        _buildEmailForm(),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Error message
                        if (_errorMessage != null) _buildErrorMessage(),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Reset button
                        _buildResetButton(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Tips
                        _buildTips(),
                      ] else ...[
                        // Success state
                        _buildSuccessContent(),
                      ],
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Back to login
                      _buildBackToLogin(),
                      
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
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _emailSent 
                ? context.colors.freshGreen 
                : context.colors.marketOrange,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: Icon(
            _emailSent ? Icons.email_outlined : Icons.lock_reset,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Title
        Text(
          _emailSent ? 'Check Your Email' : 'Reset Password',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Subtitle
        Text(
          _emailSent 
              ? 'We\'ve sent password reset instructions to your email address'
              : 'Enter your email address and we\'ll send you instructions to reset your password',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        validator: _validateEmail,
        onFieldSubmitted: (_) => _handleResetPassword(),
        decoration: InputDecoration(
          labelText: 'Email Address',
          hintText: 'Enter your registered email address',
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

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleResetPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.marketOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusLG,
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Send Reset Instructions',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.ecoBlue.withOpacity(0.1),
        border: Border.all(
          color: context.colors.ecoBlue.withOpacity(0.3),
        ),
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: context.colors.ecoBlue,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Reset Password Tips',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          _buildTipItem('Check your spam/junk folder if you don\'t see the email'),
          _buildTipItem('Make sure you entered the correct email address'),
          _buildTipItem('The reset link will expire in 24 hours'),
          _buildTipItem('Contact support if you continue having issues'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.ecoBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      children: [
        // Success icon with animation
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: context.colors.freshGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: context.colors.freshGreen,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Success message
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: context.colors.freshGreen.withOpacity(0.1),
            border: Border.all(
              color: context.colors.freshGreen.withOpacity(0.3),
            ),
            borderRadius: AppRadius.radiusLG,
          ),
          child: Column(
            children: [
              Text(
                'Email Sent Successfully!',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.freshGreen,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              Text(
                'We\'ve sent password reset instructions to:',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.xs),
              
              Text(
                _emailController.text,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Resend button
        OutlinedButton.icon(
          onPressed: _resendEmail,
          icon: Icon(
            Icons.refresh,
            color: context.colors.freshGreen,
          ),
          label: Text(
            'Resend Email',
            style: TextStyle(
              color: context.colors.freshGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.colors.freshGreen),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusLG,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_back,
          size: 16,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: _navigateToLogin,
          child: Text(
            'Back to Sign In',
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