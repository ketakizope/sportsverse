import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:sportsverse_app/providers/auth_provider.dart';
import 'package:sportsverse_app/api/student_api.dart';

class StudentFaceCaptureScreen extends StatefulWidget {
  const StudentFaceCaptureScreen({Key? key}) : super(key: key);

  @override
  State<StudentFaceCaptureScreen> createState() => _StudentFaceCaptureScreenState();
}

class _StudentFaceCaptureScreenState extends State<StudentFaceCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _hasFaceEncoding = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkExistingFaceEncoding();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Try to use front camera first, fallback to back camera
        CameraDescription selectedCamera = _cameras![0];
        for (int i = 0; i < _cameras!.length; i++) {
          if (_cameras![i].lensDirection == CameraLensDirection.front) {
            selectedCamera = _cameras![i];
            _selectedCameraIndex = i;
            break;
          }
        }

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        
        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
      setState(() {
        _statusMessage = 'Camera initialization failed: $e. Please check camera permissions in device settings.';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    setState(() {
      _isInitialized = false;
    });

    await _cameraController?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    final selectedCamera = _cameras![_selectedCameraIndex];

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Camera switch error: $e');
      setState(() {
        _statusMessage = 'Camera switch failed: $e';
      });
    }
  }

  Future<void> _checkExistingFaceEncoding() async {
    try {
      // Check if student already has face encoding
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // You can add an API call here to check if face encoding exists
        // For now, we'll assume it doesn't exist
        setState(() {
          _hasFaceEncoding = false;
        });
      }
    } catch (e) {
      print('Error checking face encoding: $e');
    }
  }

  Future<void> _captureFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _statusMessage = 'Capturing face...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      
      setState(() {
        _isCapturing = false;
        _isProcessing = true;
        _statusMessage = 'Processing face encoding...';
      });

      // Upload face image for encoding
      await _uploadFaceForEncoding(image.path);
      
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
        _statusMessage = 'Error capturing image: $e';
      });
    }
  }

  Future<void> _uploadFaceForEncoding(String imagePath) async {
    try {
      final result = await StudentApi.uploadFaceForEncoding(imagePath);
      
      setState(() {
        _isProcessing = false;
        _hasFaceEncoding = true;
        _statusMessage = 'Face encoding generated successfully!';
      });

      // Show success dialog
      _showSuccessDialog(result);
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error generating face encoding: $e';
      });
      
      // Show error dialog
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Face encoding generated successfully!'),
            const SizedBox(height: 8),
            Text('Student: ${result['student_name']}'),
            Text('Encoding Length: ${result['encoding_length']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Attendance Setup'),
        backgroundColor: const Color(0xFF006C62),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF006C62), Color(0xFF004D47)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _hasFaceEncoding ? Icons.face : Icons.face_retouching_natural,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasFaceEncoding ? 'Face Registered' : 'Register Your Face',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasFaceEncoding 
                        ? 'Your face is registered for attendance'
                        : 'Capture your face for automated attendance',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Camera Preview
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _buildCameraPreview(),
                  ),
                ),
              ),
              
              // Status Message
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Instructions:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Look directly at the camera\n'
                      '• Ensure good lighting\n'
                      '• Keep your face centered\n'
                      '• Remove glasses if possible\n'
                      '• Grant camera permission if prompted',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Capture Button
                    if (!_hasFaceEncoding)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isInitialized && !_isCapturing && !_isProcessing) 
                            ? _captureFace 
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF006C62),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isCapturing || _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006C62)),
                                ),
                              )
                            : const Text(
                                'Capture Face',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    
                    if (_hasFaceEncoding)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Retry button if camera failed
                    if (!_isInitialized && _statusMessage != null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            _initializeCamera();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Retry Camera',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        
        // Face detection overlay
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _hasFaceEncoding ? Colors.green : Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Center(
              child: Icon(
                Icons.face,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        
        // Camera switch button
        if (_cameras != null && _cameras!.length > 1)
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              onPressed: _switchCamera,
              backgroundColor: Colors.black54,
              child: const Icon(
                Icons.switch_camera,
                color: Colors.white,
              ),
            ),
          ),
        
        // Status overlay
        if (_isCapturing || _isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
