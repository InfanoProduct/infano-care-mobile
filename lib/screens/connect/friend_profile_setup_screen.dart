import 'package:flutter/material.dart';
import '../../services/friends_api.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/local_storage_service.dart';

class FriendProfileSetupScreen extends StatefulWidget {
  final int initialStep;
  final bool isWidenRadius;

  const FriendProfileSetupScreen({
    Key? key,
    this.initialStep = 0,
    this.isWidenRadius = false,
  }) : super(key: key);

  @override
  State<FriendProfileSetupScreen> createState() => _FriendProfileSetupScreenState();
}

class _FriendProfileSetupScreenState extends State<FriendProfileSetupScreen> {
  late PageController _pageController;
  late FriendsApi _friendsApi;
  late int _currentStep;
  bool _isLoading = false;

  // Profile Data
  String _nickname = '';
  final List<String> _selectedVibeTags = [];
  final List<String> _selectedIntents = [];
  String _proximityPreference = 'Same city';
  bool _locationGranted = false;
  
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  // Constants
  final List<String> _vibeTags = [
    'Books', 'Art', 'Music', 'Sport', 'Gaming', 'Cooking', 'Nature', 'Fashion', 'Tech', 'Dance', 'Writing', 'Film',
    'Introvert', 'Extrovert', 'Homebody', 'Adventurer', 'Thinker', 'Maker', 'Empath', 'Leader',
    'Kindness', 'Honesty', 'Loyalty', 'Creativity', 'Justice', 'Humour', 'Growth', 'Quiet',
  ];
  final List<String> _intents = [
    'Someone to chat with online',
    'A study or creative partner',
    'Someone to meet up with nearby',
    'A support buddy during tough times',
    'Just exploring — no pressure'
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: widget.initialStep);
    _friendsApi = FriendsApi(ApiService.instance.dio);
    
    if (widget.isWidenRadius) {
      _loadExistingProfile();
    }
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _friendsApi.getProfile();
      if (profile != null) {
        setState(() {
          _nickname = profile.nickname ?? '';
          _selectedVibeTags.clear();
          _selectedVibeTags.addAll(profile.vibeTags);
          _selectedIntents.clear();
          _selectedIntents.addAll(profile.intent);
          _proximityPreference = profile.discoveryRadius ?? 'Same city';
          // Location status is handled separately by the geolocator check
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && (_nickname.length < 3 || _nickname.length > 20)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nickname must be 3-20 characters')));
      return;
    }
    if (_currentStep == 1 && _selectedVibeTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 vibe tag')));
      return;
    }
    if (_currentStep == 2 && _selectedIntents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 intent')));
      return;
    }
    // Step 3 = Location Privacy — require permission before advancing
    if (_currentStep == 3) {
      if (!_locationGranted) {
        _requestLocationPermission();
        return;
      }
    }

    if (_currentStep < 4) {
      if (widget.isWidenRadius && _currentStep == 3) {
        _submitProfile();
      } else {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    } else {
      _submitProfile();
    }
  }

  Future<void> _requestLocationPermission() async {
    // Check if service is enabled first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable Location Services on your device.')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission is permanently denied. Please enable it in Settings.'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    setState(() => _locationGranted = granted);

    if (granted && mounted) {
      // Advance to the next step automatically once granted
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: Colors.pink,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _selectedPhoto = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
      }
    }
  }

  Future<void> _submitProfile() async {
    setState(() => _isLoading = true);
    try {
      await _friendsApi.optInAndSetupProfile({
        'nickname': _nickname,
        'vibeTags': _selectedVibeTags,
        'intent': _selectedIntents,
        'discoveryRadius': _proximityPreference,
      });
      
      if (mounted) {
        final storage = Provider.of<LocalStorageService>(context, listen: false);
        await storage.setIsFriendOnboarded(true);
        Navigator.pop(context, true); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
        title: Text(widget.isWidenRadius ? 'Update Discovery Radius' : 'Setup Profile (${_currentStep + 1}/5)'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isWidenRadius)
              LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildNicknameStep(),
                  _buildVibeTagsStep(),
                  _buildIntentStep(),
                  _buildProximityStep(),
                  _buildPhotoStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          (_currentStep == 4 || (widget.isWidenRadius && _currentStep == 3)) ? 'Complete Profile' : 'Continue',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNicknameStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pick a Nickname', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This is how others will know you. Do not use your real name for safety.'),
          const SizedBox(height: 24),
          TextField(
            onChanged: (val) => _nickname = val,
            decoration: InputDecoration(
              hintText: 'e.g. SunshineVibes',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.pink)),
            ),
            maxLength: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildVibeTagsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What are your vibes?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Select up to 8 tags. (${_selectedVibeTags.length}/8)', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vibeTags.map((tag) {
              final isSelected = _selectedVibeTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                selectedColor: Colors.purple.withOpacity(0.2),
                checkmarkColor: Colors.purple,
                onSelected: (selected) {
                  setState(() {
                    if (selected && _selectedVibeTags.length < 8) {
                      _selectedVibeTags.add(tag);
                    } else if (!selected) {
                      _selectedVibeTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What are you looking for?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select 1 or 2 options.'),
          const SizedBox(height: 24),
          ..._intents.map((intent) {
            final isSelected = _selectedIntents.contains(intent);
            return CheckboxListTile(
              title: Text(intent),
              value: isSelected,
              activeColor: Colors.pink,
              onChanged: (val) {
                setState(() {
                  if (val == true && _selectedIntents.length < 2) {
                    _selectedIntents.add(intent);
                  } else if (val == false) {
                    _selectedIntents.remove(intent);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProximityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Location Privacy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('We never share your exact GPS. We group you into an approximate 5km area.'),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _proximityPreference,
            decoration: InputDecoration(
              labelText: 'Discovery Radius',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'Same neighbourhood', child: Text('Same neighbourhood')),
              DropdownMenuItem(value: 'Same city', child: Text('Same city')),
              DropdownMenuItem(value: 'Within 50km', child: Text('Within 50km')),
              DropdownMenuItem(value: 'Anywhere in my country', child: Text('Anywhere in my country')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _proximityPreference = val);
            },
          ),
          const SizedBox(height: 24),
          // ── Permission status tile ──────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _locationGranted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _locationGranted ? Colors.green : Colors.orange,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _locationGranted ? Icons.location_on : Icons.location_off,
                  color: _locationGranted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locationGranted
                        ? 'Location access granted! Your position will be hashed and never shared directly.'
                        : 'Location access is needed so we can match you with friends nearby.',
                    style: TextStyle(
                      color: _locationGranted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_locationGranted) ...[  
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.my_location, color: Colors.pink),
                label: const Text('Grant Location Permission',
                    style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.pink),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _requestLocationPermission,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.shield, color: Colors.green),
                SizedBox(width: 12),
                Expanded(child: Text('Your exact location is hashed and never readable by anyone.', style: TextStyle(color: Colors.green))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Add a Photo (Optional)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('If you skip this, we will generate a cute avatar for you!'),
          ),
          const SizedBox(height: 48),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              image: _selectedPhoto != null ? DecorationImage(
                image: FileImage(_selectedPhoto!),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: _selectedPhoto == null ? const Icon(Icons.add_a_photo, size: 48, color: Colors.grey) : null,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _pickImage,
            child: Text(_selectedPhoto == null ? 'Choose Photo' : 'Change Photo', style: const TextStyle(fontSize: 16, color: Colors.pink)),
          )
        ],
      ),
    );
  }
}
