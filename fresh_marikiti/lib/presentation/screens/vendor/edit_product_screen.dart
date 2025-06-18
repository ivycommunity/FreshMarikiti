import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'dart:convert';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  
  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _lowStockController;
  
  // Form data
  String _selectedCategory = '';
  String _selectedUnit = 'piece';
  List<String> _existingImages = [];
  List<File> _newImages = [];
  List<String> _imagesToDelete = [];
  late bool _isActive;
  bool _isLoading = false;
  bool _hasChanges = false;
  
  // Categories and units
  List<String> _categories = [];
  final List<String> _units = [
    'piece', 'kg', 'g', 'liter', 'ml', 'packet', 'bundle', 'box', 'bag'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with product data
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description ?? '');
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    _lowStockController = TextEditingController(text: widget.product.lowStockThreshold.toString());
    
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit ?? 'piece';
    _existingImages = List.from(widget.product.imageUrls);
    _isActive = widget.product.isActive;
    
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
    
    _loadCategories();
    _setupChangeListeners();
    _animationController.forward();
    
    LoggerService.info('Edit product screen initialized for ${widget.product.id}', tag: 'EditProductScreen');
  }

  void _setupChangeListeners() {
    _nameController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);
    _priceController.addListener(_markAsChanged);
    _stockController.addListener(_markAsChanged);
    _lowStockController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.get('/vendor/categories');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _categories = List<String>.from(data['categories'] ?? []);
        });
      }
    } catch (e) {
      LoggerService.error('Failed to load categories', error: e, tag: 'EditProductScreen');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: context.colors.surface,
            appBar: _buildAppBar(),
            body: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(child: _buildForm()),
                          _buildBottomActions(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
          const Text(
            'Edit Product',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_hasChanges)
            const Text(
              'Unsaved changes',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
      actions: [
        if (!_isLoading) ...[
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showChangeHistory,
            tooltip: 'Change History',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Duplicate Product'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Product'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildBasicInfoSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildPricingSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildInventorySection(),
          const SizedBox(height: AppSpacing.lg),
          _buildStatusSection(),
          const SizedBox(height: 100), // Space for bottom actions
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final totalImages = _existingImages.length + _newImages.length;
    
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
                Icon(
                  Icons.photo_camera,
                  color: context.colors.freshGreen,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Product Images',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalImages/5',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            if (totalImages == 0)
              _buildImagePlaceholder()
            else
              _buildImageGrid(),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: totalImages >= 5 ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: totalImages >= 5 ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: context.colors.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add product images',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing images
          ..._existingImages.map((imageUrl) => _buildExistingImageCard(imageUrl)),
          // New images
          ..._newImages.asMap().entries.map((entry) => _buildNewImageCard(entry.key)),
          // Add button if under limit
          if (_existingImages.length + _newImages.length < 5) _buildAddImageCard(),
        ],
      ),
    );
  }

  Widget _buildExistingImageCard(String imageUrl) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusMD,
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeExistingImage(imageUrl),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageCard(int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusMD,
        image: DecorationImage(
          image: FileImage(_newImages[index]),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withValues(alpha: 0.8),
                borderRadius: AppRadius.radiusSM,
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeNewImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageCard() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusMD,
        border: Border.all(
          color: context.colors.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(
        Icons.add,
        color: context.colors.textSecondary,
        size: 32,
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
                Icon(
                  Icons.info_outline,
                  color: context.colors.ecoBlue,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Basic Information',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Product name is required';
                }
                if (value!.length < 2) {
                  return 'Product name must be at least 2 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '';
                  _markAsChanged();
                });
              },
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Category is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
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
                Icon(
                  Icons.monetization_on,
                  color: context.colors.marketOrange,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Pricing & Unit',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (KSh) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(width: AppSpacing.sm),
                
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value ?? 'piece';
                        _markAsChanged();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
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
                Icon(
                  Icons.inventory_2,
                  color: context.colors.ecoBlue,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Inventory',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: 'Current Stock *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.add_box),
                      suffixText: _selectedUnit,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Stock quantity is required';
                      }
                      final stock = int.tryParse(value!);
                      if (stock == null || stock < 0) {
                        return 'Enter a valid stock quantity';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(width: AppSpacing.sm),
                
                Expanded(
                  child: TextFormField(
                    controller: _lowStockController,
                    decoration: InputDecoration(
                      labelText: 'Low Stock Alert',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.warning),
                      suffixText: _selectedUnit,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value?.isNotEmpty ?? false) {
                        final lowStock = int.tryParse(value!);
                        if (lowStock == null || lowStock < 0) {
                          return 'Enter a valid threshold';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
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
                Icon(
                  Icons.toggle_on,
                  color: context.colors.freshGreen,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Product Status',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            SwitchListTile(
              title: const Text('Active Product'),
              subtitle: Text(
                _isActive 
                    ? 'Product is visible to connectors'
                    : 'Product is hidden from connectors',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                  _markAsChanged();
                });
              },
              activeColor: context.colors.freshGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _resetChanges,
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading || !_hasChanges ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.freshGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _newImages.add(File(image.path));
          _markAsChanged();
        });
      }
    } catch (e) {
      LoggerService.error('Failed to pick image', error: e, tag: 'EditProductScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeExistingImage(String imageUrl) {
    setState(() {
      _existingImages.remove(imageUrl);
      _imagesToDelete.add(imageUrl);
      _markAsChanged();
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _markAsChanged();
    });
  }

  void _resetChanges() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Changes'),
        content: const Text('Are you sure you want to reset all changes? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreOriginalValues();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _restoreOriginalValues() {
    setState(() {
      _nameController.text = widget.product.name;
      _descriptionController.text = widget.product.description ?? '';
      _priceController.text = widget.product.price.toString();
      _stockController.text = widget.product.stockQuantity.toString();
      _lowStockController.text = widget.product.lowStockThreshold.toString();
      _selectedCategory = widget.product.category;
      _selectedUnit = widget.product.unit ?? 'piece';
      _existingImages = List.from(widget.product.imageUrls);
      _newImages.clear();
      _imagesToDelete.clear();
      _isActive = widget.product.isActive;
      _hasChanges = false;
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new images
      List<String> newImageUrls = [];
      for (File image in _newImages) {
        final imageUrl = await _uploadImage(image);
        if (imageUrl != null) {
          newImageUrls.add(imageUrl);
        }
      }

      // Combine existing and new image URLs
      final allImageUrls = [..._existingImages, ...newImageUrls];

      // Prepare product data
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text),
        'stock_quantity': int.parse(_stockController.text),
        'low_stock_threshold': _lowStockController.text.isNotEmpty 
            ? int.parse(_lowStockController.text) 
            : 10,
        'unit': _selectedUnit,
        'images': allImageUrls,
        'images_to_delete': _imagesToDelete,
        'is_active': _isActive,
      };

      final response = await ApiService.put('/vendor/products/${widget.product.id}', productData);
      
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate successful update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Product updated successfully'),
              backgroundColor: context.colors.freshGreen,
            ),
          );
        }
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to update product', error: e, tag: 'EditProductScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await ApiService.post('/vendor/upload/image', {
        'image': base64Image,
        'filename': image.path.split('/').last,
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['image_url'];
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to upload image', error: e, tag: 'EditProductScreen');
      return null;
    }
  }

  void _showChangeHistory() {
    // TODO: Implement change history dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change history feature coming soon'),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'duplicate':
        _duplicateProduct();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _duplicateProduct() {
    NavigationService.toAddProduct();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${widget.product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    try {
      final response = await ApiService.delete('/vendor/products/${widget.product.id}');
      
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, 'deleted');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${widget.product.name}" deleted'),
              backgroundColor: context.colors.freshGreen,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to delete product', error: e, tag: 'EditProductScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 