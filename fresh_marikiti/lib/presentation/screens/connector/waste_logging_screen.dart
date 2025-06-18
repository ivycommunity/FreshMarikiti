import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

enum WasteType {
  food,
  packaging,
  organic,
  recyclable,
  nonRecyclable,
}

class WasteLoggingScreen extends StatefulWidget {
  final Order? order;

  const WasteLoggingScreen({
    super.key,
    this.order,
  });

  @override
  State<WasteLoggingScreen> createState() => _WasteLoggingScreenState();
}

class _WasteLoggingScreenState extends State<WasteLoggingScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  
  WasteType _selectedWasteType = WasteType.food;
  String _selectedVendor = '';
  final List<String> _vendors = ['Vendor A', 'Vendor B', 'Vendor C'];
  bool _isLoading = false;
  double _totalWasteToday = 0.0;
  int _totalEcoPointsToday = 0;

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
    
    _loadTodaysStats();
    _animationController.forward();
    
    LoggerService.info('Waste logging screen initialized', tag: 'WasteLoggingScreen');
  }

  Future<void> _loadTodaysStats() async {
    setState(() {
      _totalWasteToday = 12.5;
      _totalEcoPointsToday = 125;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStatsHeader(),
                      _buildWasteForm(),
                      _buildRecentEntries(),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.marketOrange,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waste Logging',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Sustainability Tracking',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _viewWasteHistory(),
          tooltip: 'View History',
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: AppSpacing.paddingMD,
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.marketOrange,
            context.colors.marketOrange.withValues(alpha: 0.8),
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
                  Icons.eco,
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
                      'Today\'s Impact',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your contribution to sustainability',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Waste Collected',
                  '${_totalWasteToday.toStringAsFixed(1)} kg',
                  Icons.delete_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Eco Points Issued',
                  _totalEcoPointsToday.toString(),
                  Icons.stars,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'CO2 Reduced',
                  '${(_totalWasteToday * 0.5).toStringAsFixed(1)} kg',
                  Icons.eco,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWasteForm() {
    return Container(
      margin: AppSpacing.paddingMD,
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.outline),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: context.colors.marketOrange,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Log New Waste Entry',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Select Vendor',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _selectedVendor.isEmpty ? null : _selectedVendor,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMD,
                ),
                hintText: 'Choose vendor',
                prefixIcon: Icon(Icons.store, color: context.colors.marketOrange),
              ),
              items: _vendors.map((vendor) => DropdownMenuItem(
                value: vendor,
                child: Text(vendor),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVendor = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a vendor';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Waste Type',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: WasteType.values.map((type) => 
                _buildWasteTypeChip(type)).toList(),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Weight (kg)',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMD,
                ),
                hintText: 'Enter weight in kg',
                prefixIcon: Icon(Icons.scale, color: context.colors.marketOrange),
                suffixText: 'kg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight <= 0) {
                  return 'Please enter a valid weight';
                }
                return null;
              },
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Notes (Optional)',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMD,
                ),
                hintText: 'Add any additional notes...',
                prefixIcon: Icon(Icons.note, color: context.colors.marketOrange),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: context.colors.ecoBlue.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
                border: Border.all(color: context.colors.ecoBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: context.colors.ecoBlue,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Eco Points Calculation',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.ecoBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weight × Points per kg:',
                        style: context.textTheme.bodyMedium,
                      ),
                      Text(
                        '${_calculateEcoPoints().toString()} points',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.ecoBlue,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Vendor will receive these eco points for sustainable practices',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitWasteEntry,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(_isLoading ? 'Logging...' : 'Log Waste Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.marketOrange,
                foregroundColor: Colors.white,
                padding: AppSpacing.paddingMD,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteTypeChip(WasteType type) {
    final isSelected = _selectedWasteType == type;
    final typeData = _getWasteTypeData(type);
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedWasteType = type;
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeData['icon'] as IconData,
            size: 16,
            color: isSelected ? Colors.white : context.colors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(typeData['label'] as String),
        ],
      ),
      backgroundColor: isSelected ? context.colors.marketOrange : null,
      selectedColor: context.colors.marketOrange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildRecentEntries() {
    return Container(
      margin: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: context.colors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Recent Entries',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _viewWasteHistory(),
                child: const Text('View All'),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => _buildRecentEntryCard(index),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntryCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.marketOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.eco,
                  color: context.colors.marketOrange,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendor ${String.fromCharCode(65 + index)}',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Food waste • ${(index + 1) * 2.5} kg',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(index + 1) * 25} eco points issued',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.ecoBlue,
                      ),
                    ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Today',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: context.colors.freshGreen,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getWasteTypeData(WasteType type) {
    switch (type) {
      case WasteType.food:
        return {'label': 'Food', 'icon': Icons.restaurant, 'points': 10};
      case WasteType.packaging:
        return {'label': 'Packaging', 'icon': Icons.inventory_2, 'points': 8};
      case WasteType.organic:
        return {'label': 'Organic', 'icon': Icons.eco, 'points': 12};
      case WasteType.recyclable:
        return {'label': 'Recyclable', 'icon': Icons.recycling, 'points': 15};
      case WasteType.nonRecyclable:
        return {'label': 'Non-recyclable', 'icon': Icons.delete, 'points': 5};
    }
  }

  int _calculateEcoPoints() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final typeData = _getWasteTypeData(_selectedWasteType);
    final pointsPerKg = typeData['points'] as int;
    return (weight * pointsPerKg).round();
  }

  Future<void> _submitWasteEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final weight = double.parse(_weightController.text);
      final ecoPoints = _calculateEcoPoints();
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _totalWasteToday += weight;
          _totalEcoPointsToday += ecoPoints;
        });
        
        _resetForm();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waste logged successfully! $ecoPoints eco points issued to $_selectedVendor'),
            backgroundColor: context.colors.marketOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log waste: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    _weightController.clear();
    _notesController.clear();
    setState(() {
      _selectedVendor = '';
      _selectedWasteType = WasteType.food;
    });
  }

  void _viewWasteHistory() {
    NavigationService.toWasteDetails();
  }
} 