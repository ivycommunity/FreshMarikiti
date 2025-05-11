import 'package:flutter/material.dart';

class AdminVendorProfile extends StatefulWidget {
  final Map<String, dynamic> vendorData;
  final Function(Map<String, dynamic>) onVendorUpdated;
  final Function() onVendorDeleted;

  const AdminVendorProfile({
    Key? key,
    required this.vendorData,
    required this.onVendorUpdated,
    required this.onVendorDeleted,
  }) : super(key: key);

  @override
  State<AdminVendorProfile> createState() => _AdminVendorProfileState();
}

class _AdminVendorProfileState extends State<AdminVendorProfile> {
  late bool isEditing;
  late Map<String, dynamic> currentVendorData;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text fields
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController stallNameController;
  late TextEditingController stallLocationController;
  late TextEditingController roleController;

  @override
  void initState() {
    super.initState();
    isEditing = false;
    // Create a deep copy of the vendor data
    currentVendorData = Map.from(widget.vendorData);
    
    // Add any missing fields with default values
    currentVendorData['email'] ??= 'vendor@example.com';
    currentVendorData['phone'] ??= '+254 700 000000';
    currentVendorData['address'] ??= 'Nairobi, Kenya';
    currentVendorData['stallName'] ??= 'Default Stall';
    currentVendorData['stallLocation'] ??= 'Section A';
    currentVendorData['role'] ??= 'Vendor';
    
    // Initialize controllers
    nameController = TextEditingController(text: currentVendorData['name']);
    emailController = TextEditingController(text: currentVendorData['email']);
    phoneController = TextEditingController(text: currentVendorData['phone']);
    addressController = TextEditingController(text: currentVendorData['address']);
    stallNameController = TextEditingController(text: currentVendorData['stallName']);
    stallLocationController = TextEditingController(text: currentVendorData['stallLocation']);
    roleController = TextEditingController(text: currentVendorData['role']);
  }

  @override
  void dispose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    stallNameController.dispose();
    stallLocationController.dispose();
    roleController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
      if (!isEditing) {
        // Reset fields if canceling edit
        nameController.text = widget.vendorData['name'];
        emailController.text = widget.vendorData['email'] ?? 'vendor@example.com';
        phoneController.text = widget.vendorData['phone'] ?? '+254 700 000000';
        addressController.text = widget.vendorData['address'] ?? 'Nairobi, Kenya';
        stallNameController.text = widget.vendorData['stallName'] ?? 'Default Stall';
        stallLocationController.text = widget.vendorData['stallLocation'] ?? 'Section A';
        roleController.text = widget.vendorData['role'] ?? 'Vendor';
      }
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Update the vendor data
      Map<String, dynamic> updatedVendor = Map.from(widget.vendorData);
      updatedVendor['name'] = nameController.text;
      updatedVendor['email'] = emailController.text;
      updatedVendor['phone'] = phoneController.text;
      updatedVendor['address'] = addressController.text;
      updatedVendor['stallName'] = stallNameController.text;
      updatedVendor['stallLocation'] = stallLocationController.text;
      updatedVendor['role'] = roleController.text;
      
      // Call the update callback
      widget.onVendorUpdated(updatedVendor);
      
      // Exit edit mode
      setState(() {
        isEditing = false;
        currentVendorData = updatedVendor;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor details updated successfully')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Vendor'),
          content: Text('Are you sure you want to delete ${widget.vendorData['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                widget.onVendorDeleted(); // Call the delete callback
                Navigator.pop(context); // Go back to the vendors list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vendor deleted successfully')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vendor' : 'Vendor Profile'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.primaryColor.withOpacity(0.2),
                      child: Text(
                        currentVendorData['name'].toString().substring(0, 1),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isEditing)
                      Text(
                        currentVendorData['name'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!isEditing)
                      Text(
                        currentVendorData['role'] ?? 'Vendor',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    if (!isEditing)
                      Chip(
                        label: Text(currentVendorData['status']),
                        backgroundColor: currentVendorData['status'] == 'Active'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: currentVendorData['status'] == 'Active'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Vendor Details Form/Display
              _buildDetailSection(
                theme, 
                'Personal Information',
                [
                  if (isEditing)
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    )
                  else
                    _buildInfoRow(theme, 'Name', currentVendorData['name']),
                  
                  const SizedBox(height: 12),
                  
                  if (isEditing)
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        return null;
                      },
                    )
                  else
                    _buildInfoRow(theme, 'Email', currentVendorData['email']),
                  
                  const SizedBox(height: 12),
                  
                  if (isEditing)
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    )
                  else
                    _buildInfoRow(theme, 'Phone', currentVendorData['phone']),
                  
                  const SizedBox(height: 12),
                  
                  if (isEditing)
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    )
                  else
                    _buildInfoRow(theme, 'Address', currentVendorData['address']),
                ]
              ),
              
              const SizedBox(height: 24),
              
              _buildDetailSection(
                theme, 
                'Stall Information',
                [
                  if (isEditing)
                    TextFormField(
                      controller: stallNameController,
                      decoration: const InputDecoration(labelText: 'Stall Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a stall name';
                        }
                        return null;
                      },
                    )
                  else
                    _buildInfoRow(theme, 'Stall Name', currentVendorData['stallName']),
                  
                  const SizedBox(height: 12),
                  
                  if (isEditing)
                    TextFormField(
                      controller: stallLocationController,
                      decoration: const InputDecoration(labelText: 'Stall Location'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a stall location';
                        }
                        return null;
                      },
                    )
                  else
                    _buildInfoRow(theme, 'Stall Location', currentVendorData['stallLocation']),
                ]
              ),
              
              const SizedBox(height: 24),
              
              _buildDetailSection(
                theme, 
                'Business Information',
                [
                  _buildInfoRow(theme, 'Joined', currentVendorData['joinDate']),
                  const SizedBox(height: 12),
                  _buildInfoRow(theme, 'Total Sales', currentVendorData['sales']),
                  const SizedBox(height: 12),
                  _buildInfoRow(theme, 'Products', '${currentVendorData['products']} items'),
                  const SizedBox(height: 12),
                  _buildInfoRow(theme, 'Rating', '${currentVendorData['rating']} / 5'),
                ]
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              if (isEditing)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.amber,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Text('SAVE CHANGES'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    /*
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _toggleEditMode,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('EDIT PROFILE'),
                      ),
                    ),
                    */
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('DELETE VENDOR'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}