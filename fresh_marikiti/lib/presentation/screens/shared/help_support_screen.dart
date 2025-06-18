import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class HelpSupportScreen extends StatefulWidget {
  final String? category;
  final String? orderId;

  const HelpSupportScreen({
    super.key,
    this.category,
    this.orderId,
  });

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    LoggerService.info('Help & Support screen initialized', tag: 'HelpSupportScreen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // Search bar
              if (_isSearchMode) _buildSearchBar(),
              
              // Quick actions header
              _buildQuickActionsHeader(),
              
              // Tab bar
              _buildTabBar(context),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFAQTab(),
                    _buildContactTab(),
                    _buildTicketsTab(),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
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
        'Help & Support',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearchMode ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearchMode = !_isSearchMode;
              if (!_isSearchMode) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.headset_mic),
          onPressed: () => _startLiveChat(),
          tooltip: 'Live Chat',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.freshGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search help articles...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusLG,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildQuickActionsHeader() {
    return Container(
      padding: AppSpacing.paddingMD,
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.chat_bubble,
              title: 'Live Chat',
              subtitle: 'Chat with support',
              color: context.colors.ecoBlue,
              onTap: () => _startLiveChat(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '+254 700 123 456',
              color: context.colors.marketOrange,
              onTap: () => _callSupport(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'support@marikiti.co.ke',
              color: context.colors.freshGreen,
              onTap: () => _emailSupport(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: context.colors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: context.colors.freshGreen,
        unselectedLabelColor: context.colors.textSecondary,
        indicatorColor: context.colors.freshGreen,
        tabs: const [
          Tab(text: 'FAQ'),
          Tab(text: 'Contact'),
          Tab(text: 'My Tickets'),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final faqs = _getFilteredFAQs();

    if (faqs.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        return _buildFAQCard(faqs[index]);
      },
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Support',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Contact form
          _buildContactForm(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Support hours
          _buildSupportHours(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Social media links
          _buildSocialMediaLinks(),
        ],
      ),
    );
  }

  Widget _buildTicketsTab() {
    return Column(
      children: [
        // Ticket stats
        _buildTicketStats(),
        
        // Tickets list
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.paddingMD,
            itemCount: _getDummyTickets().length,
            itemBuilder: (context, index) {
              return _buildTicketCard(_getDummyTickets()[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: context.colors.freshGreen.withOpacity(0.2),
          child: Icon(
            faq['icon'] as IconData,
            color: context.colors.freshGreen,
          ),
        ),
        title: Text(
          faq['question'] as String,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          faq['category'] as String,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        children: [
          Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['answer'] as String,
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _rateFAQ(faq['id'] as String, true),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Helpful'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.freshGreen,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _rateFAQ(faq['id'] as String, false),
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: const Text('Not Helpful'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send us a message',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Category dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _getSupportCategories().map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Message field
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Describe your issue',
                hintText: 'Please provide as much detail as possible...',
                border: OutlineInputBorder(borderRadius: AppRadius.radiusMD),
                prefixIcon: const Icon(Icons.message),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitContactForm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.freshGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                ),
                child: const Text('Send Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHours() {
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
                Icon(Icons.access_time, color: context.colors.freshGreen),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Support Hours',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSupportHourRow('Monday - Friday', '8:00 AM - 8:00 PM'),
            _buildSupportHourRow('Saturday', '9:00 AM - 6:00 PM'),
            _buildSupportHourRow('Sunday', '10:00 AM - 4:00 PM'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: context.colors.ecoBlue.withOpacity(0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: context.colors.ecoBlue, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'We respond to all messages within 2-4 hours during business hours',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.ecoBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportHourRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            hours,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinks() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow Us',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _openSocialMedia('facebook'),
                ),
                _buildSocialButton(
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  color: const Color(0xFF1DA1F2),
                  onTap: () => _openSocialMedia('twitter'),
                ),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () => _openSocialMedia('instagram'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketStats() {
    return Container(
      padding: AppSpacing.paddingMD,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Open', '2', context.colors.marketOrange),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard('In Progress', '1', context.colors.ecoBlue),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard('Resolved', '5', context.colors.freshGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: context.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTicketStatusColor(ticket['status']).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTicketStatusIcon(ticket['status']),
            color: _getTicketStatusColor(ticket['status']),
          ),
        ),
        title: Text(
          ticket['title'] as String,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Ticket #${ticket['id']}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Created: ${ticket['createdAt']}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTicketStatusColor(ticket['status']),
            borderRadius: AppRadius.radiusSM,
          ),
          child: Text(
            ticket['status'] as String,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _viewTicket(ticket),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: context.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No results found',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try different keywords or contact support directly',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _startLiveChat(),
      backgroundColor: context.colors.freshGreen,
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }

  // Helper methods and data
  List<Map<String, dynamic>> _getFilteredFAQs() {
    final faqs = _getDummyFAQs();
    if (_searchQuery.isEmpty) return faqs;
    
    return faqs.where((faq) {
      return (faq['question'] as String).toLowerCase().contains(_searchQuery) ||
             (faq['answer'] as String).toLowerCase().contains(_searchQuery) ||
             (faq['category'] as String).toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<Map<String, dynamic>> _getDummyFAQs() {
    return [
      {
        'id': '1',
        'question': 'How do I place an order?',
        'answer': 'To place an order, browse products, add items to cart, select a connector, and proceed to checkout. You can track your order in real-time.',
        'category': 'Ordering',
        'icon': Icons.shopping_cart,
      },
      {
        'id': '2',
        'question': 'What are the delivery charges?',
        'answer': 'Fresh Marikiti charges a 5% commission on the total order value. This covers delivery, connector fees, and platform maintenance.',
        'category': 'Delivery',
        'icon': Icons.delivery_dining,
      },
      {
        'id': '3',
        'question': 'How do connectors work?',
        'answer': 'Connectors are local partners who fulfill your orders. They source products from vendors and deliver to you. You can choose your preferred connector.',
        'category': 'Connectors',
        'icon': Icons.people,
      },
      {
        'id': '4',
        'question': 'What is the waste pickup program?',
        'answer': 'Our sustainability program collects organic waste for composting. Participate to earn eco-points and contribute to environmental conservation.',
        'category': 'Sustainability',
        'icon': Icons.eco,
      },
      {
        'id': '5',
        'question': 'How do I track my order?',
        'answer': 'Use the order tracking feature in the app. You\'ll receive real-time updates and can chat with your connector for updates.',
        'category': 'Tracking',
        'icon': Icons.location_on,
      },
    ];
  }

  List<String> _getSupportCategories() {
    return [
      'Order Issues',
      'Payment Problems',
      'Delivery Concerns',
      'Account Issues',
      'Technical Problems',
      'Connector Issues',
      'Product Quality',
      'Other',
    ];
  }

  List<Map<String, dynamic>> _getDummyTickets() {
    return [
      {
        'id': 'TK001',
        'title': 'Order not delivered',
        'status': 'Open',
        'createdAt': '2024-01-15',
      },
      {
        'id': 'TK002',
        'title': 'Payment refund request',
        'status': 'In Progress',
        'createdAt': '2024-01-14',
      },
      {
        'id': 'TK003',
        'title': 'Product quality issue',
        'status': 'Resolved',
        'createdAt': '2024-01-12',
      },
    ];
  }

  Color _getTicketStatusColor(String status) {
    switch (status) {
      case 'Open':
        return context.colors.marketOrange;
      case 'In Progress':
        return context.colors.ecoBlue;
      case 'Resolved':
        return context.colors.freshGreen;
      default:
        return context.colors.textSecondary;
    }
  }

  IconData _getTicketStatusIcon(String status) {
    switch (status) {
      case 'Open':
        return Icons.schedule;
      case 'In Progress':
        return Icons.pending;
      case 'Resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  // Action methods
  void _startLiveChat() {
    NavigationService.toChat();
  }

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling support... (Feature to be implemented)')),
    );
  }

  void _emailSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email app... (Feature to be implemented)')),
    );
  }

  void _rateFAQ(String faqId, bool helpful) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(helpful ? 'Thanks for your feedback!' : 'We\'ll improve this article'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _submitContactForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message sent! We\'ll respond within 2-4 hours'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _openSocialMedia(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $platform... (Feature to be implemented)'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _viewTicket(Map<String, dynamic> ticket) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ticket ${ticket['id']}...'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }
} 