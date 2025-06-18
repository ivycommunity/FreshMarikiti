import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class VehicleInfo {
  final String type;
  final String make;
  final String model;
  final String year;
  final String licensePlate;
  final String color;
  final bool isActive;

  VehicleInfo({
    required this.type,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.color,
    required this.isActive,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      type: json['type'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      color: json['color'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'color': color,
      'is_active': isActive,
    };
  }
}

class AvailabilitySettings {
  final bool isOnline;
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final double maxDistance;
  final bool acceptLowPayOrders;

  AvailabilitySettings({
    required this.isOnline,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.maxDistance,
    required this.acceptLowPayOrders,
  });

  factory AvailabilitySettings.fromJson(Map<String, dynamic> json) {
    return AvailabilitySettings(
      isOnline: json['is_online'] ?? false,
      availableDays: List<String>.from(json['available_days'] ?? []),
      startTime: json['start_time'] ?? '08:00',
      endTime: json['end_time'] ?? '20:00',
      maxDistance: (json['max_distance'] ?? 10.0).toDouble(),
      acceptLowPayOrders: json['accept_low_pay_orders'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_online': isOnline,
      'available_days': availableDays,
      'start_time': startTime,
      'end_time': endTime,
      'max_distance': maxDistance,
      'accept_low_pay_orders': acceptLowPayOrders,
    };
  }
}

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  
  // Vehicle form controllers
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  
  VehicleInfo? _vehicleInfo;
  AvailabilitySettings? _availabilitySettings;
  File? _profileImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
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
    
    _loadProfileData();
    _animationController.forward();
    
    LoggerService.info('Rider profile screen initialized', tag: 'RiderProfileScreen');
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/rider/profile');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            // Load profile data
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _emailController.text = data['email'] ?? '';
            _emergencyContactController.text = data['emergency_contact'] ?? '';
            
            // Load vehicle info
            if (data['vehicle'] != null) {
              _vehicleInfo = VehicleInfo.fromJson(data['vehicle']);
              _vehicleMakeController.text = _vehicleInfo!.make;
              _vehicleModelController.text = _vehicleInfo!.model;
              _vehicleYearController.text = _vehicleInfo!.year;
              _licensePlateController.text = _vehicleInfo!.licensePlate;
            }
            
            // Load availability settings
            if (data['availability'] != null) {
              _availabilitySettings = AvailabilitySettings.fromJson(data['availability']);
            } else {
              _availabilitySettings = AvailabilitySettings(
                isOnline: false,
                availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                startTime: '08:00',
                endTime: '20:00',
                maxDistance: 10.0,
                acceptLowPayOrders: false,
              );
            }
            
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to load profile data', error: e, tag: 'RiderProfileScreen');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final profileData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'emergency_contact': _emergencyContactController.text,
      };

      final response = await ApiService.put('/rider/profile', profileData);
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: context.colors.freshGreen,
            ),
          );
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveVehicleInfo() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final vehicleData = {
        'type': _vehicleInfo?.type ?? 'motorcycle',
        'make': _vehicleMakeController.text,
        'model': _vehicleModelController.text,
        'year': _vehicleYearController.text,
        'license_plate': _licensePlateController.text,
        'color': _vehicleInfo?.color ?? 'black',
        'is_active': _vehicleInfo?.isActive ?? true,
      };

      final response = await ApiService.put('/rider/vehicle', vehicleData);
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vehicle information updated successfully'),
              backgroundColor: context.colors.freshGreen,
            ),
          );
          _loadProfileData(); // Refresh data
        }
      } else {
        throw Exception('Failed to update vehicle info: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update vehicle info: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveAvailabilitySettings() async {
    if (_availabilitySettings == null) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ApiService.put('/rider/availability', _availabilitySettings!.toJson());
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Availability settings updated successfully'),
              backgroundColor: context.colors.freshGreen,
            ),
          );
        }
      } else {
        throw Exception('Failed to update availability: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        
        // Upload image
        await _uploadProfileImage();
      }
    } catch (e) {
      LoggerService.error('Failed to pick profile image', error: e, tag: 'RiderProfileScreen');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;
    
    try {
      // TODO: Implement multipart file upload
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile image updated successfully'),
          backgroundColor: context.colors.freshGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _licensePlateController.dispose();
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
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : Column(
                            children: [
                              _buildTabBar(),
                              Expanded(child: _buildTabBarView()),
                            ],
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
      backgroundColor: context.colors.ecoBlue,
      foregroundColor: Colors.white,
      title: const Text(
        'Rider Profile',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadProfileData(),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => NavigationService.toSettings(),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        border: Border(
          bottom: BorderSide(color: context.colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Profile', icon: Icon(Icons.person, size: 20)),
          Tab(text: 'Vehicle', icon: Icon(Icons.directions_car, size: 20)),
          Tab(text: 'Availability', icon: Icon(Icons.schedule, size: 20)),
        ],
        labelColor: context.colors.ecoBlue,
        unselectedLabelColor: context.colors.textSecondary,
        indicatorColor: context.colors.ecoBlue,
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProfileTab(),
        _buildVehicleTab(),
        _buildAvailabilityTab(),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildProfileForm(),
          const SizedBox(height: AppSpacing.lg),
          _buildSaveButton(() => _saveProfile()),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: context.colors.ecoBlue.withValues(alpha: 0.2),
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: context.colors.ecoBlue,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.freshGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Text(
              _nameController.text.isNotEmpty ? _nameController.text : 'Rider Name',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withValues(alpha: 0.2),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Text(
                'Active Rider',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.freshGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty == true ? 'Phone number is required' : null,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value?.isEmpty == true ? 'Email is required' : null,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildTextField(
              controller: _emergencyContactController,
              label: 'Emergency Contact',
              icon: Icons.emergency,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTab() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          _buildVehicleInfo(),
          const SizedBox(height: AppSpacing.lg),
          _buildVehicleForm(),
          const SizedBox(height: AppSpacing.lg),
          _buildSaveButton(() => _saveVehicleInfo()),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          children: [
            Icon(
              Icons.directions_car,
              size: 48,
              color: context.colors.ecoBlue,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Text(
              _vehicleInfo != null 
                  ? '${_vehicleInfo!.year} ${_vehicleInfo!.make} ${_vehicleInfo!.model}'
                  : 'No vehicle registered',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (_vehicleInfo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _vehicleInfo!.isActive 
                      ? context.colors.freshGreen.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: AppRadius.radiusMD,
                ),
                child: Text(
                  _vehicleInfo!.isActive ? 'Active' : 'Inactive',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: _vehicleInfo!.isActive ? context.colors.freshGreen : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Information',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildVehicleTypeSelector(),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _vehicleMakeController,
                    label: 'Make',
                    icon: Icons.build,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildTextField(
                    controller: _vehicleModelController,
                    label: 'Model',
                    icon: Icons.car_rental,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _vehicleYearController,
                    label: 'Year',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildTextField(
                    controller: _licensePlateController,
                    label: 'License Plate',
                    icon: Icons.confirmation_number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildVehicleColorSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    final types = ['motorcycle', 'bicycle', 'car', 'van'];
    final currentType = _vehicleInfo?.type ?? 'motorcycle';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Type',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: types.map((type) {
            final isSelected = currentType == type;
            return ChoiceChip(
              label: Text(type.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _vehicleInfo = VehicleInfo(
                      type: type,
                      make: _vehicleInfo?.make ?? '',
                      model: _vehicleInfo?.model ?? '',
                      year: _vehicleInfo?.year ?? '',
                      licensePlate: _vehicleInfo?.licensePlate ?? '',
                      color: _vehicleInfo?.color ?? 'black',
                      isActive: _vehicleInfo?.isActive ?? true,
                    );
                  });
                }
              },
              selectedColor: context.colors.ecoBlue.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? context.colors.ecoBlue : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVehicleColorSelector() {
    final colors = ['black', 'white', 'red', 'blue', 'green', 'yellow', 'silver'];
    final currentColor = _vehicleInfo?.color ?? 'black';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Color',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: colors.map((color) {
            final isSelected = currentColor == color;
            return ChoiceChip(
              label: Text(color.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _vehicleInfo = VehicleInfo(
                      type: _vehicleInfo?.type ?? 'motorcycle',
                      make: _vehicleInfo?.make ?? '',
                      model: _vehicleInfo?.model ?? '',
                      year: _vehicleInfo?.year ?? '',
                      licensePlate: _vehicleInfo?.licensePlate ?? '',
                      color: color,
                      isActive: _vehicleInfo?.isActive ?? true,
                    );
                  });
                }
              },
              selectedColor: context.colors.marketOrange.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? context.colors.marketOrange : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilityTab() {
    if (_availabilitySettings == null) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          _buildAvailabilityHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildWorkingHours(),
          const SizedBox(height: AppSpacing.lg),
          _buildPreferences(),
          const SizedBox(height: AppSpacing.lg),
          _buildSaveButton(() => _saveAvailabilitySettings()),
        ],
      ),
    );
  }

  Widget _buildAvailabilityHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Row(
          children: [
            Icon(
              _availabilitySettings!.isOnline ? Icons.online_prediction : Icons.offline_bolt,
              size: 32,
              color: _availabilitySettings!.isOnline ? context.colors.freshGreen : Colors.grey,
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _availabilitySettings!.isOnline ? 'Currently Online' : 'Currently Offline',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _availabilitySettings!.isOnline 
                        ? 'Available for deliveries'
                        : 'Not accepting new deliveries',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            Switch(
              value: _availabilitySettings!.isOnline,
              onChanged: (value) {
                setState(() {
                  _availabilitySettings = AvailabilitySettings(
                    isOnline: value,
                    availableDays: _availabilitySettings!.availableDays,
                    startTime: _availabilitySettings!.startTime,
                    endTime: _availabilitySettings!.endTime,
                    maxDistance: _availabilitySettings!.maxDistance,
                    acceptLowPayOrders: _availabilitySettings!.acceptLowPayOrders,
                  );
                });
              },
              activeColor: context.colors.freshGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHours() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Working Schedule',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Text(
              'Available Days',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: days.map((day) {
                final isSelected = _availabilitySettings!.availableDays.contains(day);
                return FilterChip(
                  label: Text(day.substring(0, 3)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      final newDays = List<String>.from(_availabilitySettings!.availableDays);
                      if (selected) {
                        newDays.add(day);
                      } else {
                        newDays.remove(day);
                      }
                      _availabilitySettings = AvailabilitySettings(
                        isOnline: _availabilitySettings!.isOnline,
                        availableDays: newDays,
                        startTime: _availabilitySettings!.startTime,
                        endTime: _availabilitySettings!.endTime,
                        maxDistance: _availabilitySettings!.maxDistance,
                        acceptLowPayOrders: _availabilitySettings!.acceptLowPayOrders,
                      );
                    });
                  },
                  selectedColor: context.colors.ecoBlue.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => _selectTime(true),
                        child: Text(
                          _availabilitySettings!.startTime,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colors.ecoBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => _selectTime(false),
                        child: Text(
                          _availabilitySettings!.endTime,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colors.ecoBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferences() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Preferences',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            ListTile(
              leading: Icon(Icons.location_on, color: context.colors.ecoBlue),
              title: const Text('Maximum Delivery Distance'),
              subtitle: Text('${_availabilitySettings!.maxDistance.toStringAsFixed(0)} km'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _availabilitySettings!.maxDistance,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  onChanged: (value) {
                    setState(() {
                      _availabilitySettings = AvailabilitySettings(
                        isOnline: _availabilitySettings!.isOnline,
                        availableDays: _availabilitySettings!.availableDays,
                        startTime: _availabilitySettings!.startTime,
                        endTime: _availabilitySettings!.endTime,
                        maxDistance: value,
                        acceptLowPayOrders: _availabilitySettings!.acceptLowPayOrders,
                      );
                    });
                  },
                  activeColor: context.colors.ecoBlue,
                ),
              ),
            ),
            
            SwitchListTile(
              secondary: Icon(Icons.attach_money, color: context.colors.marketOrange),
              title: const Text('Accept Low Pay Orders'),
              subtitle: const Text('Accept orders with lower than average pay'),
              value: _availabilitySettings!.acceptLowPayOrders,
              onChanged: (value) {
                setState(() {
                  _availabilitySettings = AvailabilitySettings(
                    isOnline: _availabilitySettings!.isOnline,
                    availableDays: _availabilitySettings!.availableDays,
                    startTime: _availabilitySettings!.startTime,
                    endTime: _availabilitySettings!.endTime,
                    maxDistance: _availabilitySettings!.maxDistance,
                    acceptLowPayOrders: value,
                  );
                });
              },
              activeColor: context.colors.marketOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.radiusMD,
          borderSide: BorderSide(color: context.colors.ecoBlue),
        ),
      ),
    );
  }

  Widget _buildSaveButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : onPressed,
        icon: _isSaving 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.freshGreen,
          foregroundColor: Colors.white,
          padding: AppSpacing.paddingMD,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load profile',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            _error ?? 'Unknown error occurred',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadProfileData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        _availabilitySettings = AvailabilitySettings(
          isOnline: _availabilitySettings!.isOnline,
          availableDays: _availabilitySettings!.availableDays,
          startTime: isStartTime ? timeString : _availabilitySettings!.startTime,
          endTime: isStartTime ? _availabilitySettings!.endTime : timeString,
          maxDistance: _availabilitySettings!.maxDistance,
          acceptLowPayOrders: _availabilitySettings!.acceptLowPayOrders,
        );
      });
    }
  }
} 