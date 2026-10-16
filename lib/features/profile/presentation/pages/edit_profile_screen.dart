import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_event.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algohary_project/core/network/firebase_config.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategoryId;
  List<String> _selectedServices = [];
  String? _selectedGovernorateId;
  List<String> _selectedCities = [];
  late TextEditingController _aboutController;

  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  late Future<QuerySnapshot> _categoriesFuture = _firestore.collection('categories').get();
  Future<QuerySnapshot>? _servicesFuture;
  late Future<QuerySnapshot> _governoratesFuture = _firestore.collection('governorates').get();
  Future<QuerySnapshot>? _citiesFuture;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _aboutController = TextEditingController(text: widget.user.about);
    
    if (widget.user.userType == 'provider') {
      _selectedCategoryId = widget.user.categoryId;
      _selectedServices = List.from(widget.user.services ?? []);
      _selectedGovernorateId = widget.user.governorateId;
      _selectedCities = List.from(widget.user.cities ?? []);
      
      if (_selectedCategoryId != null) {
        _servicesFuture = _firestore.collection('services').where('category_id', isEqualTo: _selectedCategoryId).get();
      }
      if (_selectedGovernorateId != null) {
        _citiesFuture = _firestore.collection('cities').where('governorate_id', isEqualTo: _selectedGovernorateId).get();
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image != null && mounted) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  void _submitUpdate(BuildContext context, AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    context.read<AuthBloc>().add(
      UpdateProfileRequested(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: _profileImage,
        categoryId: widget.user.userType == 'provider' ? _selectedCategoryId : null,
        services: widget.user.userType == 'provider' ? _selectedServices : null,
        governorateId: widget.user.userType == 'provider' ? _selectedGovernorateId : null,
        cities: widget.user.userType == 'provider' ? _selectedCities : null,
        about: widget.user.userType == 'provider' ? _aboutController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0.5,
        title: Text(
          l10n.editProfile,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: AlignmentDirectional.bottomEnd,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: kIsWeb
                                    ? Image.network(
                                        _profileImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_profileImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : widget.user.imageUrl.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: widget.user.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_outline,
                                    size: 50,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      hintText: l10n.signupFirstName,
                      icon: Icons.person_outline,
                      theme: theme,
                      controller: _firstNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.errorRequiredField;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      hintText: l10n.signupLastName,
                      icon: Icons.person_outline,
                      theme: theme,
                      controller: _lastNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.errorRequiredField;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Email Field (Read Only)
              _buildTextField(
                hintText: l10n.signupEmail,
                icon: Icons.email_outlined,
                theme: theme,
                controller: _emailController,
                readOnly: true, // Email usually cannot be changed without re-auth
              ),
              const SizedBox(height: 16),
              
              // Phone Field
              _buildTextField(
                hintText: l10n.phone,
                icon: Icons.phone_outlined,
                theme: theme,
                controller: _phoneController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.errorRequiredField;
                  }
                  return null;
                },
              ),
              
              if (widget.user.userType == 'provider') ...[
                const SizedBox(height: 16),
                _buildProviderFields(theme, isAr, l10n),
              ],
              
              const SizedBox(height: 40),
              
              // Save Button
              SizedBox(
                height: 56,
                child: BlocConsumer<AuthBloc, AuthState>(
                  // Only the outcome of a save request (Loading -> Success/Failure)
                  // may close this screen; unrelated AuthSuccess emissions (e.g. the
                  // state being restored after a failed save) must not.
                  listenWhen: (previous, current) =>
                      previous is AuthLoading &&
                      (current is AuthSuccess || current is AuthFailure),
                  listener: (context, state) {
                    if (state is AuthSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.saveChanges),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    } else if (state is AuthFailure) {
                      debugPrint('Update Error: ${state.message}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.errorGeneric),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is AuthLoading
                          ? null
                          : () => _submitUpdate(context, l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: state is AuthLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(l10n.saveChanges),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    required ThemeData theme,
    bool readOnly = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly 
          ? theme.colorScheme.onSurface.withOpacity(0.5) 
          : theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        filled: true,
        fillColor: readOnly ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) : theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildProviderFields(ThemeData theme, bool isAr, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          hintText: l10n.appAbout,
          icon: Icons.info_outline,
          theme: theme,
          controller: _aboutController,
        ),
        const SizedBox(height: 16),
        FutureBuilder<QuerySnapshot>(
          future: _governoratesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
            final docs = snapshot.data!.docs;
            return DropdownButtonFormField<String>(
              value: _selectedGovernorateId,
              decoration: _buildInputDecoration(theme).copyWith(
                prefixIcon: Icon(Icons.location_city, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              dropdownColor: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
              style: TextStyle(color: theme.colorScheme.onSurface),
              hint: Text(l10n.appSelectGovernorate),
              items: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(isAr ? (data['governorate_name_ar'] ?? '') : (data['governorate_name_en'] ?? '')),
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
        const SizedBox(height: 16),
        if (_selectedGovernorateId != null && _citiesFuture != null)
          FutureBuilder<QuerySnapshot>(
            future: _citiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
              final docs = snapshot.data!.docs;
              return _buildMultiSelectDropdown(
                theme: theme,
                title: l10n.appSelectCities,
                items: docs,
                selectedIds: _selectedCities,
                icon: Icons.location_on_outlined,
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
        if (_selectedGovernorateId != null && _citiesFuture != null) const SizedBox(height: 16),
        FutureBuilder<QuerySnapshot>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
            final docs = snapshot.data!.docs;
            return DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: _buildInputDecoration(theme).copyWith(
                prefixIcon: Icon(Icons.category_outlined, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              dropdownColor: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
              style: TextStyle(color: theme.colorScheme.onSurface),
              hint: Text(l10n.appSelectCategory),
              items: docs.map((doc) {
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
        const SizedBox(height: 16),
        if (_selectedCategoryId != null && _servicesFuture != null)
          FutureBuilder<QuerySnapshot>(
            future: _servicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
              final docs = snapshot.data!.docs;
              return _buildMultiSelectDropdown(
                theme: theme,
                title: l10n.appSelectServices,
                items: docs,
                selectedIds: _selectedServices,
                icon: Icons.design_services_outlined,
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
      ],
    );
  }

  InputDecoration _buildInputDecoration(ThemeData theme) {
    return InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
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
    IconData? icon,
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
        decoration: _buildInputDecoration(theme).copyWith(
          prefixIcon: icon != null ? Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedIds.isEmpty ? title : selectedNames,
                style: TextStyle(
                  color: selectedIds.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.onSurface,
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
          child: Text(AppLocalizations.of(context)!.appBack, style: const TextStyle(fontWeight: FontWeight.bold)),
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
