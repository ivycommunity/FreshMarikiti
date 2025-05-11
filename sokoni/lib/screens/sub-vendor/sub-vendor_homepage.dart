import 'package:flutter/material.dart';

class SubVendorHomePage extends StatelessWidget {
  const SubVendorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sub-Vendor Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _greetingCard(theme),
            const SizedBox(height: 16),
            _buildOverviewCards(theme, isDark),
            const SizedBox(height: 24),
            Text(
              "Quick Actions",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _greetingCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.person_pin_circle, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Hi Shadrack 👋\nYou're assigned to 'Mama Mboga Stall'.",
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _overviewCard("Today’s Sales", "KES 3,200", Icons.attach_money_outlined,
            Colors.green, theme),
        _overviewCard("Orders", "15", Icons.shopping_cart_outlined,
            Colors.orange, theme),
        _overviewCard("Products", "120", Icons.category_outlined,
            Colors.purple, theme),
        _overviewCard("Tasks", "2 Pending", Icons.task_outlined,
            Colors.redAccent, theme),
      ],
    );
  }

  Widget _overviewCard(String title, String value, IconData icon, Color color,
      ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _quickActionButton("Make Sale", Icons.point_of_sale_outlined, theme),
        _quickActionButton("View Inventory", Icons.inventory_2_outlined, theme),
        _quickActionButton("View Orders", Icons.receipt_long_outlined, theme),
        _quickActionButton("Report Issue", Icons.report_gmailerrorred_outlined, theme),
      ],
    );
  }

  Widget _quickActionButton(String label, IconData icon, ThemeData theme) {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
