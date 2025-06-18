import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _logoAnimationController.forward();
    LoggerService.info('About screen initialized', tag: 'AboutScreen');
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: SingleChildScrollView(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App logo and title
                _buildAppHeader(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // App info cards
                _buildAppInfoSection(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Mission statement
                _buildMissionSection(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Team section
                _buildTeamSection(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Legal section
                _buildLegalSection(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Contact section
                _buildContactSection(),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Copyright
                _buildCopyright(),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'About Fresh Marikiti',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareApp(),
          tooltip: 'Share App',
        ),
      ],
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _logoAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _logoAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colors.freshGreen,
                      context.colors.marketOrange,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.freshGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Fresh Marikiti',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Connecting Communities, Sustaining Tomorrow',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.info,
                title: 'Version',
                subtitle: '1.0.0 (Beta)',
                color: context.colors.ecoBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.download,
                title: 'Build',
                subtitle: '2024.01.15',
                color: context.colors.marketOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.android,
                title: 'Platform',
                subtitle: 'Android/iOS',
                color: context.colors.freshGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.code,
                title: 'Framework',
                subtitle: 'Flutter',
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLG,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
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
    );
  }

  Widget _buildMissionSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLG,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.freshGreen.withOpacity(0.1),
              context.colors.ecoBlue.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.eco,
                  color: context.colors.freshGreen,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Our Mission',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Fresh Marikiti revolutionizes local commerce by connecting customers with community connectors who source fresh produce from local vendors. Our innovative 5% commission model ensures fair pricing while our sustainability program transforms waste into wealth.',
              style: context.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFeatureList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      'Community-driven marketplace',
      'Sustainable waste management',
      'Real-time order tracking',
      'Fair commission structure',
      'Local vendor support',
    ];

    return Column(
      children: features.map((feature) => 
        _buildFeatureItem(feature)
      ).toList(),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: context.colors.freshGreen,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              feature,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: context.colors.ecoBlue,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Meet Our Team',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Fresh Marikiti is built by a passionate team of developers, designers, and sustainability advocates committed to transforming local commerce in Kenya.',
              style: context.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Team members
            ..._getTeamMembers().map((member) => 
              _buildTeamMember(member)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMember(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: context.colors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: member['color'] as Color,
            child: Text(
              member['initials'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] as String,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  member['role'] as String,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.link,
              color: context.colors.freshGreen,
            ),
            onPressed: () => _viewProfile(member['name'] as String),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel,
                  color: context.colors.marketOrange,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Legal & Privacy',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            _buildLegalItem(
              title: 'Privacy Policy',
              subtitle: 'How we protect your data',
              onTap: () => _viewPrivacyPolicy(),
            ),
            _buildLegalItem(
              title: 'Terms of Service',
              subtitle: 'User agreement and conditions',
              onTap: () => _viewTermsOfService(),
            ),
            _buildLegalItem(
              title: 'Open Source Licenses',
              subtitle: 'Third-party software licenses',
              onTap: () => _viewLicenses(),
            ),
            _buildLegalItem(
              title: 'Data Usage Policy',
              subtitle: 'How we handle your information',
              onTap: () => _viewDataPolicy(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
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
        Icons.arrow_forward_ios,
        size: 16,
        color: context.colors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_support,
                  color: context.colors.freshGreen,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Get In Touch',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            
            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'hello@freshmarikiti.co.ke',
              onTap: () => _sendEmail(),
            ),
            _buildContactItem(
              icon: Icons.phone,
              title: 'Phone',
              subtitle: '+254 700 123 456',
              onTap: () => _callUs(),
            ),
            _buildContactItem(
              icon: Icons.location_on,
              title: 'Address',
              subtitle: 'Nairobi, Kenya',
              onTap: () => _viewLocation(),
            ),
            _buildContactItem(
              icon: Icons.language,
              title: 'Website',
              subtitle: 'www.freshmarikiti.co.ke',
              onTap: () => _visitWebsite(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: context.colors.freshGreen.withOpacity(0.2),
        child: Icon(icon, color: context.colors.freshGreen),
      ),
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildCopyright() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        children: [
          Text(
            '© 2024 Fresh Marikiti',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Made with ❤️ in Kenya',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook, () => _openSocial('facebook')),
              const SizedBox(width: AppSpacing.sm),
              _buildSocialIcon(Icons.alternate_email, () => _openSocial('twitter')),
              const SizedBox(width: AppSpacing.sm),
              _buildSocialIcon(Icons.camera_alt, () => _openSocial('instagram')),
              const SizedBox(width: AppSpacing.sm),
              _buildSocialIcon(Icons.video_library, () => _openSocial('youtube')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.freshGreen.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: context.colors.freshGreen,
          size: 20,
        ),
      ),
    );
  }

  // Helper methods
  List<Map<String, dynamic>> _getTeamMembers() {
    return [
      {
        'name': 'Alex Kiprotich',
        'role': 'Founder & CEO',
        'initials': 'AK',
        'color': context.colors.freshGreen,
      },
      {
        'name': 'Sarah Wanjiku',
        'role': 'CTO & Lead Developer',
        'initials': 'SW',
        'color': context.colors.ecoBlue,
      },
      {
        'name': 'David Mwangi',
        'role': 'Head of Operations',
        'initials': 'DM',
        'color': context.colors.marketOrange,
      },
      {
        'name': 'Grace Achieng',
        'role': 'Sustainability Lead',
        'initials': 'GA',
        'color': Colors.purple,
      },
    ];
  }

  // Action methods
  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing Fresh Marikiti...'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _viewProfile(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing $name\'s profile...'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _viewPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Privacy Policy...')),
    );
  }

  void _viewTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Terms of Service...')),
    );
  }

  void _viewLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Fresh Marikiti',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.freshGreen, context.colors.marketOrange],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.eco, color: Colors.white, size: 30),
      ),
    );
  }

  void _viewDataPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Data Usage Policy...')),
    );
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email app...')),
    );
  }

  void _callUs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling Fresh Marikiti...')),
    );
  }

  void _viewLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening location in maps...')),
    );
  }

  void _visitWebsite() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening website...')),
    );
  }

  void _openSocial(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $platform...')),
    );
  }
} 