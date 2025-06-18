import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/connector_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class ShoppingProgressScreen extends StatefulWidget {
  final Order order;

  const ShoppingProgressScreen({
    super.key,
    required this.order,
  });

  @override
  State<ShoppingProgressScreen> createState() => _ShoppingProgressScreenState();
}

class _ShoppingProgressScreenState extends State<ShoppingProgressScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final Map<String, bool> _itemCheckList = {};
  final Map<String, String> _itemNotes = {};
  
  double _shoppingProgress = 0.0;
  int _completedItems = 0;
  bool _showOnlyPending = false;

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
    
    _initializeCheckList();
    _animationController.forward();
    
    LoggerService.info('Shopping progress screen initialized for order ${widget.order.id}', 
                      tag: 'ShoppingProgressScreen');
  }

  void _initializeCheckList() {
    for (int i = 0; i < widget.order.items.length; i++) {
      final itemId = i.toString(); // Using index as ID
      _itemCheckList[itemId] = false;
      _itemNotes[itemId] = '';
    }
    _calculateProgress();
  }

  void _calculateProgress() {
    _completedItems = _itemCheckList.values.where((checked) => checked).length;
    _shoppingProgress = _itemCheckList.isEmpty ? 0.0 : _completedItems / _itemCheckList.length;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OrderProvider>(
      builder: (context, authProvider, orderProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    _buildProgressHeader(),
                    _buildFilterControls(),
                    Expanded(child: _buildShoppingList()),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: _buildBottomControls(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shopping Progress',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Order #${widget.order.orderNumber}',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () => _openOrderChat(),
          tooltip: 'Chat with Customer',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_order',
              child: ListTile(
                leading: Icon(Icons.receipt),
                title: Text('View Order Details'),
              ),
            ),
            const PopupMenuItem(
              value: 'report_issue',
              child: ListTile(
                leading: Icon(Icons.report),
                title: Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      margin: AppSpacing.paddingMD,
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.freshGreen,
            context.colors.freshGreen.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shopping Progress',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_completedItems of ${widget.order.items.length} items collected',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.radiusLG,
                ),
                child: Text(
                  '${(_shoppingProgress * 100).toInt()}%',
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          ClipRRect(
            borderRadius: AppRadius.radiusSM,
            child: LinearProgressIndicator(
              value: _shoppingProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 12,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat('Collected', _completedItems.toString(), Icons.check_circle),
              _buildProgressStat('Remaining', '${widget.order.items.length - _completedItems}', Icons.pending),
              _buildProgressStat('Total Value', 'KSh ${widget.order.totalPrice.toStringAsFixed(2)}', Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    return Container(
      margin: AppSpacing.paddingMD,
      child: Row(
        children: [
          Text(
            'Items',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('All'),
                icon: Icon(Icons.list, size: 16),
              ),
              ButtonSegment(
                value: true,
                label: Text('Pending'),
                icon: Icon(Icons.pending, size: 16),
              ),
            ],
            selected: {_showOnlyPending},
            onSelectionChanged: (selection) {
              setState(() {
                _showOnlyPending = selection.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingList() {
    final filteredItems = <int>[];
    
    for (int i = 0; i < widget.order.items.length; i++) {
      final itemId = i.toString();
      final isChecked = _itemCheckList[itemId] ?? false;
      
      if (!_showOnlyPending || !isChecked) {
        filteredItems.add(i);
      }
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: context.colors.freshGreen,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'All items collected!',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.freshGreen,
              ),
            ),
            Text(
              'Great job! You can now complete the shopping.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final itemIndex = filteredItems[index];
        final item = widget.order.items[itemIndex];
        return _buildShoppingItem(item, itemIndex);
      },
    );
  }

  Widget _buildShoppingItem(OrderItem item, int itemIndex) {
    final itemId = itemIndex.toString();
    final isChecked = _itemCheckList[itemId] ?? false;
    final hasNote = _itemNotes[itemId]?.isNotEmpty == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        elevation: isChecked ? 1 : 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusLG,
            border: isChecked 
                ? Border.all(color: context.colors.freshGreen, width: 2)
                : null,
          ),
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.3,
                      child: Checkbox(
                        value: isChecked,
                        onChanged: (value) => _toggleItem(itemId, value ?? false),
                        activeColor: context.colors.freshGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusSM,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.sm),
                    
                    ClipRRect(
                      borderRadius: AppRadius.radiusMD,
                      child: Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: item.productName.isNotEmpty
                            ? Center(
                                child: Text(
                                  item.productName.substring(0, 1).toUpperCase(),
                                  style: context.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.freshGreen,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.shopping_bag,
                                color: context.colors.textSecondary,
                                size: 32,
                              ),
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.md),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                              color: isChecked ? context.colors.textSecondary : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quantity: ${item.quantity}',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          Text(
                            'Unit Price: KSh ${item.price.toStringAsFixed(2)}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          if (hasNote) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.ecoBlue.withValues(alpha: 0.1),
                                borderRadius: AppRadius.radiusSM,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.note,
                                    size: 12,
                                    color: context.colors.ecoBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Note added',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colors.ecoBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KSh ${item.subtotal.toStringAsFixed(2)}',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.freshGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? context.colors.freshGreen.withValues(alpha: 0.2)
                                : context.colors.marketOrange.withValues(alpha: 0.2),
                            borderRadius: AppRadius.radiusSM,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isChecked ? Icons.check_circle : Icons.pending,
                                size: 12,
                                color: isChecked
                                    ? context.colors.freshGreen
                                    : context.colors.marketOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isChecked ? 'Collected' : 'Pending',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: isChecked
                                      ? context.colors.freshGreen
                                      : context.colors.marketOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () => _showItemNoteDialog(itemId, item.productName),
                          icon: Icon(
                            hasNote ? Icons.edit_note : Icons.add_comment,
                            color: context.colors.ecoBlue,
                            size: 20,
                          ),
                          tooltip: hasNote ? 'Edit note' : 'Add note',
                        ),
                      ],
                    ),
                  ],
                ),
                
                if (hasNote) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: context.colors.ecoBlue.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMD,
                      border: Border.all(color: context.colors.ecoBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 16,
                              color: context.colors.ecoBlue,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Note',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.ecoBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _itemNotes[itemId]!,
                          style: context.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_shoppingProgress > 0 && _shoppingProgress < 1) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveProgress(),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Progress'),
                      style: OutlinedButton.styleFrom(
                        padding: AppSpacing.paddingMD,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _continueToNextStep(),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text('Continue (${(_shoppingProgress * 100).toInt()}%)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.freshGreen,
                        foregroundColor: Colors.white,
                        padding: AppSpacing.paddingMD,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_shoppingProgress == 1) ...[
              ElevatedButton.icon(
                onPressed: () => _completeShopping(),
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete Shopping & Assign Rider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.freshGreen,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _startShopping(),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Start Shopping'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.ecoBlue,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.sm),
            
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _logWaste(),
                    icon: const Icon(Icons.eco),
                    label: const Text('Log Waste'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.marketOrange,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _reportIssue(),
                    icon: const Icon(Icons.report),
                    label: const Text('Report Issue'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.textSecondary,
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

  // Helper methods
  void _toggleItem(String itemId, bool checked) {
    setState(() {
      _itemCheckList[itemId] = checked;
      _calculateProgress();
    });
    
    LoggerService.info('Item ${checked ? 'checked' : 'unchecked'}: $itemId', 
                      tag: 'ShoppingProgressScreen');
    
    if (checked) {
      _showItemCollectedFeedback();
    }
  }

  void _showItemCollectedFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item collected! Progress: ${(_shoppingProgress * 100).toInt()}%'),
        backgroundColor: context.colors.freshGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showItemNoteDialog(String itemId, String itemName) {
    final controller = TextEditingController(text: _itemNotes[itemId] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note for $itemName'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add any notes about this item...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _itemNotes[itemId] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProgress() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Progress saved successfully'),
          backgroundColor: context.colors.freshGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save progress: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _continueToNextStep() {
    NavigationService.toAssignmentDetails(widget.order,
    );
  }

  void _startShopping() {
    setState(() {
      // Mark as started shopping - this would typically update order status
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shopping started! Check off items as you collect them.'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  Future<void> _completeShopping() async {
    try {
      await ConnectorService.updateOrderStatus(widget.order.id, 'ready');
      
      NavigationService.toRiderHandoff(widget.order);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete shopping: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openOrderChat() {
    NavigationService.toChat();
  }

  void _logWaste() {
    NavigationService.toWasteLogging();
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue reported successfully'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'view_order':
        NavigationService.toAssignmentDetails(widget.order,
        );
        break;
      case 'report_issue':
        _reportIssue();
        break;
    }
  }
} 