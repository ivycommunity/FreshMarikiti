import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/location_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabAnimation;
  
  bool _isLoading = false;
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _loadAddresses();
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fabAnimationController.forward();
    });
    LoggerService.info('Addresses screen initialized', tag: 'AddressesScreen');
  }

  void _loadAddresses() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.loadSavedAddresses();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationProvider, AuthProvider>(
      builder: (context, locationProvider, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: _buildAddressesContent(locationProvider),
                ),
              );
            },
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
        'Delivery Addresses',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: () => _openMap(),
        ),
      ],
    );
  }

  Widget _buildAddressesContent(LocationProvider locationProvider) {
    if (_isLoading || locationProvider.isLoading) {
      return _buildLoadingState();
    }
    
    if (locationProvider.error != null) {
      return _buildErrorState(locationProvider);
    }
    
    if (locationProvider.savedAddresses.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () => _refreshAddresses(locationProvider),
      color: context.colors.freshGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingMD,
        child: Column(
          children: [
            // Current location card
            _buildCurrentLocationCard(locationProvider),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Saved addresses header
            Row(
              children: [
                Text(
                  'Saved Addresses',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${locationProvider.savedAddresses.length} locations',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Addresses list
            ...locationProvider.savedAddresses.asMap().entries.map((entry) {
              final index = entry.key;
              final address = entry.value;
              return _buildAddressCard(address, index, locationProvider);
            }),
            
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard(LocationProvider locationProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.ecoBlue,
              context.colors.ecoBlue.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Current Location',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            Text(
              locationProvider.currentAddress ?? 'Location not detected',
              style: context.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _getCurrentLocation(locationProvider),
                    icon: const Icon(Icons.gps_fixed, size: 16),
                    label: const Text('Use Current'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: context.colors.ecoBlue,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () => _saveCurrentLocation(locationProvider),
                  icon: const Icon(Icons.bookmark_add, size: 16),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, int index, LocationProvider locationProvider) {
    final isDefault = address['isDefault'] ?? false;
    final isSelected = address['id'] == _selectedAddressId;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                elevation: isSelected ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusLG,
                  side: BorderSide(
                    color: isSelected 
                        ? context.colors.freshGreen 
                        : isDefault 
                            ? context.colors.marketOrange.withValues(alpha: 0.5)
                            : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: AppRadius.radiusLG,
                  onTap: () => _selectAddress(address, locationProvider),
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDefault 
                                    ? context.colors.marketOrange 
                                    : context.colors.freshGreen).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getAddressIcon(address['type'] ?? 'other'),
                                color: isDefault 
                                    ? context.colors.marketOrange 
                                    : context.colors.freshGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        address['label'] ?? 'Address',
                                        style: context.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isDefault) ...[
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: context.colors.marketOrange,
                                            borderRadius: AppRadius.radiusSM,
                                          ),
                                          child: Text(
                                            'Default',
                                            style: context.textTheme.bodySmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _getAddressTypeDisplay(address['type'] ?? 'other'),
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: context.colors.textSecondary,
                              ),
                              onSelected: (action) => _handleAddressAction(action, address, locationProvider),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                if (!isDefault)
                                  const PopupMenuItem(
                                    value: 'setDefault',
                                    child: Row(
                                      children: [
                                        Icon(Icons.star),
                                        SizedBox(width: 8),
                                        Text('Set as Default'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Address details
                        Text(
                          address['address'] ?? 'No address provided',
                          style: context.textTheme.bodyMedium,
                        ),
                        
                        if (address['details'] != null && address['details'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            address['details'],
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _navigateToAddress(address),
                                icon: const Icon(Icons.directions, size: 16),
                                label: const Text('Directions'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.colors.ecoBlue),
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _selectAddress(address, locationProvider),
                                icon: Icon(
                                  isSelected ? Icons.check : Icons.location_on,
                                  size: 16,
                                ),
                                label: Text(isSelected ? 'Selected' : 'Use This'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected 
                                      ? context.colors.freshGreen 
                                      : context.colors.freshGreen.withValues(alpha: 0.8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () => _addNewAddress(),
            backgroundColor: context.colors.freshGreen,
            icon: const Icon(Icons.add_location, color: Colors.white),
            label: const Text(
              'Add Address',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Loading addresses...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(LocationProvider locationProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Failed to load addresses',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locationProvider.error ?? 'Something went wrong',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => _refreshAddresses(locationProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No saved addresses',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add delivery addresses for faster checkout',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => _addNewAddress(),
            icon: const Icon(Icons.add_location),
            label: const Text('Add First Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'office':
        return Icons.business;
      case 'school':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }

  String _getAddressTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return 'Home Address';
      case 'work':
        return 'Work Address';
      case 'office':
        return 'Office Address';
      case 'school':
        return 'School Address';
      default:
        return 'Other Location';
    }
  }

  Future<void> _refreshAddresses(LocationProvider locationProvider) async {
    await locationProvider.loadSavedAddresses();
  }

  void _getCurrentLocation(LocationProvider locationProvider) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await locationProvider.getCurrentLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Current location updated'),
          backgroundColor: context.colors.freshGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: context.colors.marketOrange,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveCurrentLocation(LocationProvider locationProvider) {
    if (locationProvider.currentAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No current location to save'),
          backgroundColor: context.colors.marketOrange,
        ),
      );
      return;
    }
    
    _showAddAddressDialog(
      initialAddress: locationProvider.currentAddress!,
      isCurrentLocation: true,
    );
  }

  void _selectAddress(Map<String, dynamic> address, LocationProvider locationProvider) {
    setState(() {
      _selectedAddressId = address['id'];
    });
    
    locationProvider.setCurrentAddress(address['address']);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${address['label']} as delivery address'),
        backgroundColor: context.colors.freshGreen,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _handleAddressAction(String action, Map<String, dynamic> address, LocationProvider locationProvider) {
    switch (action) {
      case 'edit':
        _editAddress(address);
        break;
      case 'setDefault':
        _setDefaultAddress(address, locationProvider);
        break;
      case 'delete':
        _showDeleteConfirmation(address, locationProvider);
        break;
    }
  }

  void _addNewAddress() {
    _showAddAddressDialog();
  }

  void _editAddress(Map<String, dynamic> address) {
    _showAddAddressDialog(
      address: address,
      isEditing: true,
    );
  }

  void _setDefaultAddress(Map<String, dynamic> address, LocationProvider locationProvider) async {
    try {
      await locationProvider.setDefaultAddress(address['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${address['label']} set as default address'),
          backgroundColor: context.colors.freshGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set default address: $e'),
          backgroundColor: context.colors.marketOrange,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> address, LocationProvider locationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address['label']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await locationProvider.deleteAddress(address['id']);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${address['label']} deleted successfully'),
                    backgroundColor: context.colors.freshGreen,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete address: $e'),
                    backgroundColor: context.colors.marketOrange,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog({
    Map<String, dynamic>? address,
    bool isEditing = false,
    String? initialAddress,
    bool isCurrentLocation = false,
  }) {
    final labelController = TextEditingController(text: address?['label'] ?? '');
    final addressController = TextEditingController(text: address?['address'] ?? initialAddress ?? '');
    final detailsController = TextEditingController(text: address?['details'] ?? '');
    String selectedType = address?['type'] ?? 'home';
    bool setAsDefault = address?['isDefault'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Address Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('Home')),
                    DropdownMenuItem(value: 'work', child: Text('Work')),
                    DropdownMenuItem(value: 'office', child: Text('Office')),
                    DropdownMenuItem(value: 'school', child: Text('School')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Label
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (e.g., Home, Office)',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Address
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Full Address',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        // Implementation for getting current location
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Getting current location...'),
                            backgroundColor: context.colors.ecoBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Additional details
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    hintText: 'Apartment number, landmark, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Set as default
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: setAsDefault,
                  onChanged: (value) {
                    setState(() {
                      setAsDefault = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (labelController.text.isEmpty || addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please fill in required fields'),
                      backgroundColor: context.colors.marketOrange,
                    ),
                  );
                  return;
                }
                
                final addressData = {
                  'id': address?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  'type': selectedType,
                  'label': labelController.text,
                  'address': addressController.text,
                  'details': detailsController.text,
                  'isDefault': setAsDefault,
                };
                
                Navigator.pop(context);
                
                try {
                  final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                  if (isEditing) {
                    await locationProvider.updateAddress(addressData);
                  } else {
                    await locationProvider.saveAddress(addressData);
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing 
                          ? 'Address updated successfully' 
                          : 'Address added successfully'),
                      backgroundColor: context.colors.freshGreen,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save address: $e'),
                      backgroundColor: context.colors.marketOrange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.freshGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddress(Map<String, dynamic> address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${address['label']}...'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _openMap() {
    NavigationService.toMap();
  }
} 