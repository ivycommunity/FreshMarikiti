import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isEditing = false;
  bool _isSaving = false;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalOffers = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _initializeUserData();
    _animationController.forward();
    LoggerService.info('Customer profile screen initialized', tag: 'CustomerProfileScreen');
  }

  void _initializeUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _emailController.text = user.email;
      }
      
      // Load order provider data
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.loadOrders(refresh: true);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, OrderProvider, NotificationProvider>(
      builder: (context, authProvider, orderProvider, notificationProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(authProvider),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: _buildProfileContent(authProvider, orderProvider, notificationProvider),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.colors.freshGreen,
                context.colors.freshGreen.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Space for app bar
                
                // Profile avatar
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _changeProfilePicture(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.colors.marketOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // User name
                Text(
                  authProvider.user?.name ?? 'Guest User',
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // User type badge
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusLG,
                  ),
                  child: Text(
                    'Premium Customer',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            onPressed: () => _toggleEdit(),
            icon: const Icon(Icons.edit),
          )
        else
          TextButton(
            onPressed: _isSaving ? null : () => _saveProfile(authProvider),
            child: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildProfileContent(
    AuthProvider authProvider, 
    OrderProvider orderProvider, 
    NotificationProvider notificationProvider,
  ) {
    return Padding(
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          // Quick stats
          _buildQuickStats(orderProvider),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Personal information
          _buildPersonalInformation(authProvider),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Preferences
          _buildPreferences(notificationProvider),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Quick actions
          _buildQuickActions(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Account actions
          _buildAccountActions(authProvider),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildQuickStats(OrderProvider orderProvider) {
    final stats = orderProvider.getOrderStatistics();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Statistics',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Orders',
                    stats['totalOrders'].toString(),
                    Icons.receipt_long,
                    context.colors.ecoBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    stats['completedOrders'].toString(),
                    Icons.check_circle,
                    context.colors.freshGreen,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    'KSh ${stats['totalSpent'].toStringAsFixed(0)}',
                    Icons.attach_money,
                    context.colors.marketOrange,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    'Active Orders',
                    stats['activeOrders'].toString(),
                    Icons.local_shipping,
                    context.colors.ecoBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation(AuthProvider authProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Personal Information',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  TextButton(
                    onPressed: () => _toggleEdit(),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Full Name
            _buildInfoField(
              'Full Name',
              _nameController,
              Icons.person,
              _isEditing,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Phone Number
            _buildInfoField(
              'Phone Number',
              _phoneController,
              Icons.phone,
              _isEditing,
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Email
            _buildInfoField(
              'Email Address',
              _emailController,
              Icons.email,
              _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isEditing, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isEditing 
                ? context.colors.surfaceColor 
                : context.colors.textSecondary.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusMD,
            border: isEditing 
                ? Border.all(color: context.colors.freshGreen)
                : null,
          ),
          child: TextField(
            controller: controller,
            enabled: isEditing,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, 
                  color: isEditing 
                      ? context.colors.freshGreen 
                      : context.colors.textSecondary),
              border: InputBorder.none,
              contentPadding: AppSpacing.paddingMD,
            ),
            style: context.textTheme.bodyMedium?.copyWith(
              color: isEditing 
                  ? context.colors.textPrimary 
                  : context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferences(NotificationProvider notificationProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Notifications
            _buildSwitchTile(
              'Push Notifications',
              'Receive push notifications on your device',
              Icons.notifications,
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            
            const Divider(),
            
            // Email notifications
            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              Icons.email,
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            
            const Divider(),
            
            // Order updates
            _buildSwitchTile(
              'Order Updates',
              'Get notified about order status changes',
              Icons.local_shipping,
              _orderUpdates,
              (value) => setState(() => _orderUpdates = value),
            ),
            
            const Divider(),
            
            // Promotional offers
            _buildSwitchTile(
              'Promotional Offers',
              'Receive offers and discounts',
              Icons.local_offer,
              _promotionalOffers,
              (value) => setState(() => _promotionalOffers = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: context.colors.freshGreen),
      title: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: context.colors.freshGreen,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Addresses',
                    'Manage delivery locations',
                    Icons.location_on,
                    context.colors.ecoBlue,
                    () => NavigationService.toAddresses(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildActionButton(
                    'Payment',
                    'Payment methods',
                    Icons.payment,
                    context.colors.marketOrange,
                    () => NavigationService.toPaymentMethods(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Favorites',
                    'Saved products',
                    Icons.favorite,
                    Colors.red,
                    () => NavigationService.toFavorites(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildActionButton(
                    'Reviews',
                    'My reviews',
                    Icons.star,
                    Colors.amber,
                    () => NavigationService.toReviews(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.radiusMD,
        onTap: onPressed,
        child: Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusMD,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActions(AuthProvider authProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Help & Support
            _buildActionTile(
              'Help & Support',
              'Get help or contact support',
              Icons.help_outline,
              context.colors.ecoBlue,
              () => NavigationService.toHelpSupport(),
            ),
            
            const Divider(),
            
            // About
            _buildActionTile(
              'About Fresh Marikiti',
              'Learn more about our mission',
              Icons.info_outline,
              context.colors.freshGreen,
              () => NavigationService.toAbout(),
            ),
            
            const Divider(),
            
            // Privacy Policy
            _buildActionTile(
              'Privacy Policy',
              'How we protect your data',
              Icons.privacy_tip_outlined,
              context.colors.textSecondary,
              () => _showPrivacyPolicy(),
            ),
            
            const Divider(),
            
            // Sign Out
            _buildActionTile(
              'Sign Out',
              'Sign out of your account',
              Icons.logout,
              Colors.red,
              () => _showSignOutDialog(authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: context.colors.textSecondary,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Helper methods
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile(AuthProvider authProvider) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Simulate saving profile
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: context.colors.freshGreen,
        ),
      );
      
      LoggerService.info('Profile updated successfully', tag: 'CustomerProfileScreen');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: context.colors.marketOrange,
        ),
      );
      
      LoggerService.error('Failed to update profile', error: e, tag: 'CustomerProfileScreen');
    }
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Picture',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement camera functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Camera functionality coming soon'),
                          backgroundColor: context.colors.ecoBlue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.freshGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement gallery functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Gallery functionality coming soon'),
                          backgroundColor: context.colors.ecoBlue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.ecoBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Fresh Marikiti is committed to protecting your privacy. We collect and use your information to provide better services, process orders, and improve your experience.\n\n'
            'We do not share your personal information with third parties without your consent, except as required by law or to process your orders.\n\n'
            'For more information, please visit our website or contact our support team.',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (mounted) {
                NavigationService.toLogin();
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 