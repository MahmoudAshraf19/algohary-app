import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:algohary_project/features/auth/presentation/pages/provider_onboarding/application_submitted_screen.dart';
import 'package:algohary_project/core/network/firebase_config.dart';

class ProviderApplicationScreen extends StatefulWidget {
  const ProviderApplicationScreen({super.key});

  @override
  State<ProviderApplicationScreen> createState() => _ProviderApplicationScreenState();
}

class _ProviderApplicationScreenState extends State<ProviderApplicationScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Step 0 Form (Personal Info)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  Country _selectedCountry = CountryParser.parseCountryCode('EG');
  XFile? _profileImage;
  String? _existingProfileImageUrl;

  // Step 1 Form
  String? _selectedCategoryId;
  List<String> _selectedServices = [];

  // Step 2 Form
  String? _selectedGovernorateId;
  List<String> _selectedCities = [];

  // Step 3 Form
  XFile? _idFrontImage;
  XFile? _idBackImage;

  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late Future<QuerySnapshot> _categoriesFuture = _firestore.collection('categories').get();
  Future<QuerySnapshot>? _servicesFuture;
  
  late Future<QuerySnapshot> _governoratesFuture = _firestore.collection('governorates').get();
  Future<QuerySnapshot>? _citiesFuture;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _firstNameController.text = authState.user.firstName;
      _lastNameController.text = authState.user.lastName;
      
      String phone = authState.user.phone ?? '';
      if (phone.isNotEmpty) {
        final countries = CountryService().getAll();
        // Sort by length of phone code descending to match longest code first
        countries.sort((a, b) => b.phoneCode.length.compareTo(a.phoneCode.length));
        
        bool found = false;
        if (phone.startsWith('+')) {
          for (final c in countries) {
            if (phone.startsWith('+${c.phoneCode}')) {
              _selectedCountry = c;
              phone = phone.substring(c.phoneCode.length + 1);
              found = true;
              break;
            }
          }
        } else if (phone.startsWith('00')) {
          for (final c in countries) {
            if (phone.startsWith('00${c.phoneCode}')) {
              _selectedCountry = c;
              phone = phone.substring(c.phoneCode.length + 2);
              found = true;
              break;
            }
          }
        }
      }
      _phoneController.text = phone;
      _emailController.text = authState.user.email;
      _existingProfileImageUrl = authState.user.imageUrl;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront, {bool isProfile = false}) async {
    try {
      final XFile? originalImage = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (originalImage != null) {
        final originalBytes = await originalImage.readAsBytes();
        final originalSizeKb = originalBytes.lengthInBytes / 1024;
        debugPrint('====================================');
        debugPrint('📸 ORIGINAL IMAGE SIZE: ${originalSizeKb.toStringAsFixed(2)} KB');

        final tempDir = await getTemporaryDirectory();
        final targetPath = '${tempDir.path}/compress_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        XFile? compressedImage;
        try {
          if (kIsWeb) {
            // Web doesn't need file path, compressWithList is fine, but XFile.fromData creates an empty path.
            // On web, NetworkImage(XFile.path) works if it's an object URL, which pickImage provides.
            // We'll just use the original image on web to avoid empty path issues, or we can use the original since upload handles it.
            compressedImage = originalImage;
          } else {
            compressedImage = await FlutterImageCompress.compressAndGetFile(
              originalImage.path,
              targetPath,
              minHeight: 800,
              minWidth: 800,
              quality: 60,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Compression failed (fallback to original): $e');
        }

        compressedImage ??= originalImage;
        
        final compressedBytes = await compressedImage.readAsBytes();
        final compressedSizeKb = compressedBytes.lengthInBytes / 1024;
        debugPrint('✅ COMPRESSED SIZE: ${compressedSizeKb.toStringAsFixed(2)} KB');
        debugPrint('📉 REDUCED BY: ${((1 - (compressedSizeKb / originalSizeKb)) * 100).toStringAsFixed(1)}%');
        debugPrint('====================================');

        setState(() {
          if (isProfile) {
            _profileImage = compressedImage;
          } else if (isFront) {
            _idFrontImage = compressedImage;
          } else {
            _idBackImage = compressedImage;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _submitApplication() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedCategoryId == null || _selectedServices.isEmpty || 
        _selectedGovernorateId == null || _selectedCities.isEmpty || 
        _idFrontImage == null || _idBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.appRequiredField ?? 'All fields are required!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthSuccess) {
        throw Exception("User not authenticated");
      }
      final userId = authState.user.id;

      // Upload Images
      final frontRef = _storage.ref().child('provider_applications/$userId/id_front.jpg');
      final backRef = _storage.ref().child('provider_applications/$userId/id_back.jpg');
      
      String frontUrl = '';
      String backUrl = '';
      String profileUrl = _existingProfileImageUrl ?? '';

      if (kIsWeb) {
        final frontBytes = await _idFrontImage!.readAsBytes();
        await frontRef.putData(frontBytes);
        frontUrl = await frontRef.getDownloadURL();

        final backBytes = await _idBackImage!.readAsBytes();
        await backRef.putData(backBytes);
        backUrl = await backRef.getDownloadURL();

        if (_profileImage != null) {
          final profileRef = _storage.ref().child('users/$userId/profile.jpg');
          final profileBytes = await _profileImage!.readAsBytes();
          await profileRef.putData(profileBytes);
          profileUrl = await profileRef.getDownloadURL();
        }
      } else {
        await frontRef.putFile(File(_idFrontImage!.path));
        frontUrl = await frontRef.getDownloadURL();

        await backRef.putFile(File(_idBackImage!.path));
        backUrl = await backRef.getDownloadURL();
        
        if (_profileImage != null) {
          final profileRef = _storage.ref().child('users/$userId/profile.jpg');
          await profileRef.putFile(File(_profileImage!.path));
          profileUrl = await profileRef.getDownloadURL();
        }
      }

      final String shortAppId = (10000 + Random().nextInt(90000)).toString();

      // Create Application document
      final applicationRef = _firestore.collection('provider_applications').doc(userId);
      await applicationRef.set({
        'application_id': shortAppId,
        'user_id': userId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
        'category_id': _selectedCategoryId,
        'services': _selectedServices,
        'governorate_id': _selectedGovernorateId,
        'cities': _selectedCities,
        'id_front_url': frontUrl,
        'id_back_url': backUrl,
        'status': 'under_review',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update User Document
      await _firestore.collection('users').doc(userId).update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
        'image_url': profileUrl,
        'application_status': 'under_review',
      });

      if (mounted) {
        setState(() => _isLoading = false);
        // Show success and navigate to ApplicationSubmittedScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ApplicationSubmittedScreen(applicationId: userId, shortAppId: shortAppId)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(color: theme.colorScheme.onSurface),
        title: Text(l10n.becomeProvider ?? 'Become a Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.vertical, // Changed to vertical to fix overflow
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || _phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appRequiredField ?? '')));
                    return;
                  }
                } else if (_currentStep == 1) {
                  if (_selectedCategoryId == null || _selectedServices.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appRequiredField ?? '')));
                    return;
                  }
                } else if (_currentStep == 2) {
                  if (_selectedGovernorateId == null || _selectedCities.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appRequiredField ?? '')));
                    return;
                  }
                } else if (_currentStep == 3) {
                  if (_idFrontImage == null || _idBackImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appRequiredField ?? '')));
                    return;
                  }
                  _submitApplication();
                  return;
                }
                setState(() => _currentStep += 1);
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _currentStep == 3 ? (l10n.appSubmit ?? 'Submit') : (l10n.appNext ?? 'Next'),
                            style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              l10n.appBack ?? 'Back',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: Text(l10n.appPersonalInfo ?? 'Personal Info', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildPersonalInfoStep(theme, isAr, l10n),
                ),
                Step(
                  title: Text(l10n.appStepCategory ?? 'Category', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildCategoryStep(theme, isAr, l10n),
                ),
                Step(
                  title: Text(l10n.appStepLocation ?? 'Location', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: _buildLocationStep(theme, isAr, l10n),
                ),
                Step(
                  title: Text(l10n.appStepId ?? 'Identity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  isActive: _currentStep >= 3,
                  content: _buildIdentityStep(theme, isAr, l10n),
                ),
              ],
            ),
    );
  }

  Widget _buildPersonalInfoStep(ThemeData theme, bool isAr, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.appIdNotice ?? 'Please ensure your name matches your ID card exactly, and your profile photo matches the person on the ID card.',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage: _profileImage != null
                    ? (kIsWeb ? NetworkImage(_profileImage!.path) : FileImage(File(_profileImage!.path))) as ImageProvider
                    : (_existingProfileImageUrl != null && _existingProfileImageUrl!.isNotEmpty
                        ? NetworkImage(_existingProfileImageUrl!)
                        : null),
                child: _profileImage == null && (_existingProfileImageUrl == null || _existingProfileImageUrl!.isEmpty)
                    ? Icon(Icons.person, size: 50, color: theme.colorScheme.onSurfaceVariant)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickImage(false, isProfile: true),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.camera_alt, size: 18, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _firstNameController,
          decoration: _inputDecoration(theme).copyWith(labelText: l10n.appFirstName ?? 'First Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lastNameController,
          decoration: _inputDecoration(theme).copyWith(labelText: l10n.appLastName ?? 'Last Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(theme).copyWith(
            labelText: l10n.appPhone ?? 'Phone Number',
            prefixIcon: GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  countryListTheme: CountryListThemeData(
                    borderRadius: BorderRadius.circular(16),
                    backgroundColor: theme.colorScheme.surface,
                    textStyle: const TextStyle(fontSize: 12),
                    searchTextStyle: const TextStyle(fontSize: 14),
                    inputDecoration: InputDecoration(
                      hintText: l10n.appSearch ?? 'Search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  onSelect: (Country country) {
                    setState(() {
                      _selectedCountry = country;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedCountry.flagEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('+${_selectedCountry.phoneCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          enabled: false,
          decoration: _inputDecoration(theme).copyWith(
            labelText: l10n.appEmail ?? 'Email',
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStep(ThemeData theme, bool isAr, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(l10n.appSelectCategory ?? 'Select Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
            if (snapshot.hasError) {
              debugPrint('Error loading categories: ${snapshot.error}');
              return const Text('No categories found');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No categories found');
            final docs = snapshot.data!.docs;
            final availableDocs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['available'] == true || data['is_available'] == true;
            }).toList();
            return DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: _inputDecoration(theme),
              dropdownColor: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              menuMaxHeight: 350,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
              hint: Text(l10n.appSelectCategory ?? 'Select Category'),
              items: availableDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(isAr ? (data['name_ar'] ?? '') : (data['name_en'] ?? '')),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategoryId = val;
                  _selectedServices.clear();
                  if (val != null) {
                    _servicesFuture = _firestore.collection('services').where('category_id', isEqualTo: val).get();
                  } else {
                    _servicesFuture = null;
                  }
                });
              },
            );
          },
        ),
        const SizedBox(height: 24),
        if (_selectedCategoryId != null && _servicesFuture != null) ...[
          Text(l10n.appSelectServices ?? 'Select Services', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<QuerySnapshot>(
            future: _servicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              if (snapshot.hasError) {
                debugPrint('Error loading services: ${snapshot.error}');
                return const Text('No services found');
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No services found');
              final docs = snapshot.data!.docs;
              final availableDocs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['available'] == true || data['is_available'] == true;
              }).toList();
              return _buildMultiSelectDropdown(
                theme: theme,
                title: l10n.appSelectServices ?? 'Select Services',
                items: availableDocs,
                selectedIds: _selectedServices,
                onChanged: (val) {
                  setState(() {
                    _selectedServices = val;
                  });
                },
                isAr: isAr,
                nameArKey: 'name_ar',
                nameEnKey: 'name_en',
              );
            },
          ),
        ]
      ],
    );
  }

  Widget _buildLocationStep(ThemeData theme, bool isAr, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(l10n.appSelectGovernorate ?? 'Select Governorate', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot>(
          future: _governoratesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No governorates found');
            final docs = snapshot.data!.docs;
            return DropdownButtonFormField<String>(
              value: _selectedGovernorateId,
              decoration: _inputDecoration(theme),
              dropdownColor: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              menuMaxHeight: 350,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
              hint: Text(l10n.appSelectGovernorate ?? 'Select Governorate'),
              items: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(isAr ? data['governorate_name_ar'] : data['governorate_name_en']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedGovernorateId = val;
                  _selectedCities.clear();
                  if (val != null) {
                    _citiesFuture = _firestore.collection('cities').where('governorate_id', isEqualTo: val).get();
                  } else {
                    _citiesFuture = null;
                  }
                });
              },
            );
          },
        ),
        const SizedBox(height: 24),
        if (_selectedGovernorateId != null && _citiesFuture != null) ...[
          Text(l10n.appSelectCities ?? 'Select Cities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<QuerySnapshot>(
            future: _citiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No cities found');
              final docs = snapshot.data!.docs;
              return _buildMultiSelectDropdown(
                theme: theme,
                title: l10n.appSelectCities ?? 'Select Cities',
                items: docs,
                selectedIds: _selectedCities,
                onChanged: (val) {
                  setState(() {
                    _selectedCities = val;
                  });
                },
                isAr: isAr,
                nameArKey: 'city_name_ar',
                nameEnKey: 'city_name_en',
              );
            },
          ),
        ]
      ],
    );
  }

  Widget _buildIdentityStep(ThemeData theme, bool isAr, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(l10n.appUploadIdFront ?? 'ID Card (Front)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildImagePickerBox(theme, true, _idFrontImage, l10n),
        const SizedBox(height: 24),
        Text(l10n.appUploadIdBack ?? 'ID Card (Back)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildImagePickerBox(theme, false, _idBackImage, l10n),
      ],
    );
  }

  Widget _buildImagePickerBox(ThemeData theme, bool isFront, XFile? image, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _pickImage(isFront),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: image != null ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14.5),
                child: kIsWeb ? Image.network(image.path, fit: BoxFit.cover) : Image.file(File(image.path), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    isFront ? (l10n.appUploadIdFront ?? 'Upload Front') : (l10n.appUploadIdBack ?? 'Upload Back'),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme) {
    return InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildMultiSelectDropdown({
    required ThemeData theme,
    required String title,
    required List<dynamic> items,
    required List<String> selectedIds,
    required Function(List<String>) onChanged,
    required bool isAr,
    required String nameArKey,
    required String nameEnKey,
  }) {
    final selectedNames = items
        .where((doc) => selectedIds.contains(doc.id))
        .map((doc) => isAr ? ((doc.data() as Map<String, dynamic>)[nameArKey] ?? '') : ((doc.data() as Map<String, dynamic>)[nameEnKey] ?? ''))
        .join(', ');

    return InkWell(
      onTap: () async {
        final List<String>? result = await showDialog<List<String>>(
          context: context,
          builder: (context) {
            return _MultiSelectDialog(
              items: items,
              initialSelectedIds: selectedIds,
              isAr: isAr,
              nameArKey: nameArKey,
              nameEnKey: nameEnKey,
              title: title,
            );
          },
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: InputDecorator(
        decoration: _inputDecoration(theme),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedIds.isEmpty ? title : selectedNames,
                style: TextStyle(
                  color: selectedIds.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final List<dynamic> items;
  final List<String> initialSelectedIds;
  final bool isAr;
  final String nameArKey;
  final String nameEnKey;
  final String title;

  const _MultiSelectDialog({
    required this.items,
    required this.initialSelectedIds,
    required this.isAr,
    required this.nameArKey,
    required this.nameEnKey,
    required this.title,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      actionsPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 12),
          Divider(color: colorScheme.outline.withOpacity(0.2), height: 1),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final doc = widget.items[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = widget.isAr ? (data[widget.nameArKey] ?? '') : (data[widget.nameEnKey] ?? '');
            final isSelected = _selectedIds.contains(doc.id);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: isSelected ? colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? colorScheme.primary.withOpacity(0.3) : Colors.transparent,
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  value: isSelected,
                  activeColor: colorScheme.primary,
                  checkColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds.add(doc.id);
                      } else {
                        _selectedIds.remove(doc.id);
                      }
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(AppLocalizations.of(context)!.appBack ?? 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
