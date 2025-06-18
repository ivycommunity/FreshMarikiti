import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class CameraScreen extends StatefulWidget {
  final String? orderId;
  final String? purpose; // 'verification', 'document', 'product', 'general'

  const CameraScreen({
    super.key,
    this.orderId,
    this.purpose,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late AnimationController _shutterAnimationController;
  late AnimationController _focusAnimationController;
  late Animation<double> _shutterAnimation;
  late Animation<double> _focusAnimation;
  
  bool _isCameraInitialized = false;
  bool _isFlashEnabled = false;
  bool _isFrontCamera = false;
  bool _isCapturing = false;
  String _capturedImagePath = '';
  String _cameraMode = 'photo'; // 'photo', 'video'
  
  final List<String> _capturedImages = [];
  int _selectedImageIndex = -1;

  @override
  void initState() {
    super.initState();
    
    _shutterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shutterAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _shutterAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _initializeCamera();
    LoggerService.info('Camera screen initialized for ${widget.purpose ?? 'general'} purpose', tag: 'CameraScreen');
  }

  void _initializeCamera() {
    // Simulate camera initialization
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _shutterAnimationController.dispose();
    _focusAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Camera preview
              _buildCameraPreview(),
              
              // Camera overlay
              _buildCameraOverlay(),
              
              // Top controls
              _buildTopControls(),
              
              // Bottom controls
              _buildBottomControls(),
              
              // Side controls
              _buildSideControls(),
              
              // Captured images preview
              if (_capturedImages.isNotEmpty) _buildCapturedImagesPreview(),
              
              // Loading overlay
              if (!_isCameraInitialized) _buildLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Mock camera preview
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    Colors.grey.shade600,
                    Colors.grey.shade800,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Preview',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 18,
                    ),
                  ),
                  if (widget.purpose != null)
                    Text(
                      'Purpose: ${widget.purpose}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Focus indicator
          if (_focusAnimation.value > 0)
            AnimatedBuilder(
              animation: _focusAnimation,
              builder: (context, child) {
                return Positioned(
                  left: MediaQuery.of(context).size.width * 0.5 - 25,
                  top: MediaQuery.of(context).size.height * 0.5 - 25,
                  child: Opacity(
                    opacity: _focusAnimation.value,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Grid lines (rule of thirds)
          if (_cameraMode == 'photo') _buildGridLines(),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return CustomPaint(
      size: Size.infinite,
      painter: GridLinesPainter(),
    );
  }

  Widget _buildCameraOverlay() {
    return GestureDetector(
      onTapDown: (details) => _focusAt(details.localPosition),
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
            
            // Purpose indicator
            if (widget.purpose != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getPurposeText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            
            // Settings button
            IconButton(
              onPressed: () => _showCameraSettings(),
              icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera mode selector
            _buildCameraModeSelector(),
            
            const SizedBox(height: 20),
            
            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                GestureDetector(
                  onTap: () => _openGallery(),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: _capturedImages.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                              color: Colors.grey,
                              child: const Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
                
                // Capture button
                GestureDetector(
                  onTap: _capturePhoto,
                  child: AnimatedBuilder(
                    animation: _shutterAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _shutterAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isCapturing ? Colors.red : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Switch camera button
                IconButton(
                  onPressed: () => _switchCamera(),
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeButton('PHOTO', 'photo'),
        const SizedBox(width: 32),
        _buildModeButton('VIDEO', 'video'),
      ],
    );
  }

  Widget _buildModeButton(String label, String mode) {
    final isSelected = _cameraMode == mode;
    
    return GestureDetector(
      onTap: () => _setCameraMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSideControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          // Flash toggle
          IconButton(
            onPressed: () => _toggleFlash(),
            icon: Icon(
              _isFlashEnabled ? Icons.flash_on : Icons.flash_off,
              color: _isFlashEnabled ? Colors.yellow : Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Timer toggle
          IconButton(
            onPressed: () => _toggleTimer(),
            icon: const Icon(
              Icons.timer,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Grid toggle
          IconButton(
            onPressed: () => _toggleGrid(),
            icon: const Icon(
              Icons.grid_on,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImagesPreview() {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _capturedImages.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _selectImage(index),
              child: Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedImageIndex == index ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    color: Colors.grey,
                    child: const Icon(
                      Icons.image,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getPurposeText() {
    switch (widget.purpose) {
      case 'verification':
        return 'ID Verification';
      case 'document':
        return 'Document Capture';
      case 'product':
        return 'Product Photo';
      default:
        return 'Photo Capture';
    }
  }

  void _focusAt(Offset position) {
    _focusAnimationController.reset();
    _focusAnimationController.forward();
  }

  void _capturePhoto() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });
    
    _shutterAnimationController.forward().then((_) {
      _shutterAnimationController.reverse();
    });
    
    // Simulate photo capture
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      _isCapturing = false;
      _capturedImages.add('image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    });
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo captured successfully'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
    
    // If single photo purpose, show preview
    if (widget.purpose == 'verification' || widget.purpose == 'document') {
      _showCapturedPhotoPreview();
    }
  }

  void _showCapturedPhotoPreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey,
              child: const Center(
                child: Icon(
                  Icons.image,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Retake photo
                      setState(() {
                        _capturedImages.removeLast();
                      });
                    },
                    child: const Text('Retake', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _usePhoto();
                    },
                    child: const Text('Use Photo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _usePhoto() {
    // Return the captured photo to the calling screen
    Navigator.pop(context, {
      'imagePath': _capturedImages.last,
      'purpose': widget.purpose,
      'orderId': widget.orderId,
    });
  }

  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    
    // Simulate camera switch delay
    setState(() {
      _isCameraInitialized = false;
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashEnabled = !_isFlashEnabled;
    });
  }

  void _toggleTimer() {
    // Implementation for timer toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timer feature will be implemented'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleGrid() {
    // Implementation for grid toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grid toggle will be implemented'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _setCameraMode(String mode) {
    setState(() {
      _cameraMode = mode;
    });
  }

  void _selectImage(int index) {
    setState(() {
      _selectedImageIndex = index;
    });
  }

  void _openGallery() {
    // Implementation for opening gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery feature will be implemented'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showCameraSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_size_select_actual, color: Colors.white),
              title: const Text('Photo Resolution', style: TextStyle(color: Colors.white)),
              subtitle: const Text('4:3 • 12MP', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.white),
              title: const Text('Video Quality', style: TextStyle(color: Colors.white)),
              subtitle: const Text('1080p HD', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.white),
              title: const Text('Help', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Custom painter for grid lines
class GridLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    // Vertical lines
    final verticalSpacing = size.width / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(verticalSpacing * i, 0),
        Offset(verticalSpacing * i, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    final horizontalSpacing = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, horizontalSpacing * i),
        Offset(size.width, horizontalSpacing * i),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 