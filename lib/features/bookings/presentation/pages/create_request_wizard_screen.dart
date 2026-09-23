import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/create_request/create_request_bloc.dart';
import '../bloc/create_request/create_request_event.dart';
import '../bloc/create_request/create_request_state.dart';
import '../../data/models/booking_models.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';
import 'package:algohary_project/features/dashboard/data/repositories/provider_repository.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../../../core/network/firebase_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_picker_screen.dart';
import '../../../../core/widgets/selection_bottom_sheet.dart';

class CreateRequestWizardScreen extends StatefulWidget {
  final UserModel provider;
  final String userId;

  const CreateRequestWizardScreen({
    super.key,
    required this.provider,
    required this.userId,
  });

  @override
  State<CreateRequestWizardScreen> createState() => _CreateRequestWizardScreenState();
}

class _CreateRequestWizardScreenState extends State<CreateRequestWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // controllers for inputs
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _addressController = TextEditingController(); // used for additional notes now

  // New Location Fields
  String? _selectedGovernorateId;
  String? _selectedGovernorateName;
  String? _selectedCityId;
  String? _selectedCityName;
  bool _isOtherCity = false;
  
  final _streetController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  final _apartmentNumberController = TextEditingController();
  final _otherCityController = TextEditingController();
  LocationPickerResult? _pickedLocation;

  final ProviderRepository _providerRepo = ProviderRepository();
  List<Map<String, String>> _availableServices = [];
  bool _isLoadingServices = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoadingServices) {
      _loadProviderServices();
    }
  }

  Future<void> _loadProviderServices() async {
    if (widget.provider.services == null || widget.provider.services!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
      return;
    }

    final locale = Localizations.localeOf(context).languageCode;
    final services = await _providerRepo.getServiceDetails(widget.provider.services!, locale);
    if (mounted) {
      setState(() {
        _availableServices = services;
        _isLoadingServices = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(ThemeData theme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.brightness == Brightness.dark ? AppColors.lightYellow.withOpacity(0.5) : theme.colorScheme.onSurface.withOpacity(0.6)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
    _streetController.dispose();
    _buildingNumberController.dispose();
    _apartmentNumberController.dispose();
    _otherCityController.dispose();
    super.dispose();
  }

  void _nextPage(AppLocalizations l10n) {
    final state = context.read<CreateRequestBloc>().state;
    bool canProceed = true;

    if (_currentStep == 0 && state.selectedServices.isEmpty) {
      _showError(l10n.wizardSelectAtLeastOneService);
      canProceed = false;
    } else if (_currentStep == 1) {
      if (_dateController.text.isEmpty || _timeController.text.isEmpty) {
        _showError(l10n.wizardSelectDateAndTime);
        canProceed = false;
      } else {
        context.read<CreateRequestBloc>().add(SelectAppointmentEvent(
          date: _dateController.text,
          time: _timeController.text,
          timezone: 'Africa/Cairo',
        ));
      }
    } else if (_currentStep == 2) {
      if (_selectedGovernorateId == null) {
        _showError(l10n.pleaseSelectGovernorate ?? 'Please select a governorate');
        canProceed = false;
      } else if (_selectedCityId == null) {
        _showError(l10n.pleaseSelectCity ?? 'Please select a city');
        canProceed = false;
      } else if (_isOtherCity && _otherCityController.text.isEmpty) {
        _showError(l10n.pleaseEnterCityName ?? 'Please enter city name');
        canProceed = false;
      } else if (_streetController.text.isEmpty) {
        _showError(l10n.pleaseEnterStreet ?? 'Please enter street name');
        canProceed = false;
      } else if (_buildingNumberController.text.isEmpty) {
        _showError(l10n.pleaseEnterBuilding ?? 'Please enter building number');
        canProceed = false;
      } else if (_apartmentNumberController.text.isEmpty) {
        _showError(l10n.pleaseEnterApartment ?? 'Please enter apartment number');
        canProceed = false;
      } else {
        context.read<CreateRequestBloc>().add(SelectLocationEvent(
          LocationModel(
            latitude: _pickedLocation?.latitude ?? 0.0,
            longitude: _pickedLocation?.longitude ?? 0.0,
            geohash: '',
            formattedAddress: _pickedLocation?.formattedAddress ?? '',
            details: AddressDetailsModel(
              buildingNumber: _buildingNumberController.text,
              floor: '',
              apartmentNumber: _apartmentNumberController.text,
              street: _streetController.text,
              district: _selectedGovernorateName ?? '',
              city: _isOtherCity ? _otherCityController.text : (_selectedCityName ?? ''),
              landmark: '',
              additionalInstructions: _addressController.text,
            ),
          ),
        ));
      }
    } else if (_currentStep == 3) {
      if (!state.hasConfirmedContact) {
        _showError(l10n.wizardConfirmContact);
        canProceed = false;
      } else if (state.pricing == null) {
        _showError(l10n.wizardEnterAgreedPrice);
        canProceed = false;
      }
    }

    if (canProceed) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        context.read<CreateRequestBloc>().add(SubmitRequestEvent(
          userId: widget.userId,
          providerId: widget.provider.id,
        ));
      }
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return BlocConsumer<CreateRequestBloc, CreateRequestState>(
      listener: (context, state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.wizardSubmitSuccess)),
          );
          Navigator.pop(context);
        } else if (state.errorMessage != null) {
          _showError(state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: _previousPage,
            ),
            title: Text(
              l10n.wizardRequestService,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: state.isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildProgressBar(theme),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentStep = index;
                          });
                        },
                        children: [
                          _buildServicesStep(state, theme, l10n),
                          _buildScheduleStep(state, theme, l10n),
                          _buildLocationStep(state, theme, l10n),
                          _buildPriceStep(state, theme, l10n),
                          _buildReviewStep(state, theme, l10n),
                        ],
                      ),
                    ),
                    _buildBottomNavigationBar(theme, l10n),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryBlue : theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigationBar(ThemeData theme, AppLocalizations l10n) {
    final isLastStep = _currentStep == _totalSteps - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.wizardPrevious, style: const TextStyle(fontSize: 16)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _nextPage(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isLastStep ? l10n.wizardConfirmAndSubmit : l10n.wizardNext,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Services ---
  Widget _buildServicesStep(CreateRequestState state, ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.wizardStep1Title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.wizardStep1Subtitle}${widget.provider.firstName}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          if (_isLoadingServices)
            const Center(child: CircularProgressIndicator())
          else if (_availableServices.isEmpty)
            Center(child: Text(l10n.wizardNoServices))
          else
            ..._availableServices.map((service) {
              final isSelected = state.selectedServices.any((s) => s.serviceId == service['id']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    if (isSelected) {
                      context.read<CreateRequestBloc>().add(RemoveServiceEvent(service['id']!));
                    } else {
                      context.read<CreateRequestBloc>().add(
                            SelectServiceEvent(SelectedServiceModel(
                              serviceId: service['id']!,
                              serviceName: service['name']!,
                              categoryName: widget.provider.categoryId ?? '',
                              quantity: 1,
                            )),
                          );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : theme.colorScheme.onSurface.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : theme.colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppColors.primaryBlue : Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            service['name']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primaryBlue : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // --- Step 2: Schedule ---
  Widget _buildScheduleStep(CreateRequestState state, ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.wizardStep2Title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.wizardStep2Subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _dateController.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                });
              }
            },
            decoration: InputDecoration(
              labelText: l10n.wizardDateHint,
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _timeController,
            readOnly: true,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() {
                  _timeController.text = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                });
              }
            },
            decoration: InputDecoration(
              labelText: l10n.wizardTimeHint,
              prefixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Location ---
  Widget _buildLocationStep(CreateRequestState state, ThemeData theme, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.wizardStep3Title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.wizardStep3Subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Map Picker Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
                );
                if (result != null && result is LocationPickerResult) {
                  setState(() {
                    _pickedLocation = result;
                  });
                }
              },
              icon: Icon(Icons.map, color: theme.colorScheme.primary),
              label: Text(l10n.pickLocationFromMap ?? 'Pick Location from Map'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_pickedLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              _pickedLocation!.formattedAddress,
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
            ),
          ],
          
          const SizedBox(height: 24),

          // Governorate Dropdown
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseConfig.firestore.collection('governorates').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final govDocs = snapshot.data!.docs;
              return GestureDetector(
                onTap: () async {
                  final items = govDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = isAr ? data['governorate_name_ar'] : data['governorate_name_en'];
                    return SelectionItem(id: doc.id, name: name ?? '');
                  }).toList();

                  final selected = await SelectionBottomSheet.show(
                    context,
                    title: l10n.governorate ?? 'Governorate',
                    items: items,
                  );

                  if (selected != null) {
                    setState(() {
                      _selectedGovernorateId = selected.id;
                      _selectedGovernorateName = selected.name;
                      _selectedCityId = null; // reset city when gov changes
                      _isOtherCity = false;
                      _selectedCityName = '';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    key: ValueKey(_selectedGovernorateName), // Force rebuild on change
                    initialValue: (_selectedGovernorateName?.isNotEmpty ?? false) ? _selectedGovernorateName : null,
                    decoration: _buildInputDecoration(theme, l10n.governorate ?? 'Governorate').copyWith(
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),

          // City Dropdown
          if (_selectedGovernorateId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseConfig.firestore
                  .collection('cities')
                  .where('governorate_id', isEqualTo: _selectedGovernorateId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final cityDocs = snapshot.data!.docs;
                return GestureDetector(
                  onTap: () async {
                    final itemsList = cityDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = isAr ? data['city_name_ar'] : data['city_name_en'];
                      return SelectionItem(id: doc.id, name: name ?? '');
                    }).toList();

                    // Add "Other" option
                    itemsList.add(SelectionItem(id: 'other', name: l10n.otherCity ?? 'Other City'));

                    final selected = await SelectionBottomSheet.show(
                      context,
                      title: l10n.city ?? 'City',
                      items: itemsList,
                    );

                    if (selected != null) {
                      setState(() {
                        _selectedCityId = selected.id;
                        _isOtherCity = selected.id == 'other';
                        if (!_isOtherCity) {
                          _selectedCityName = selected.name;
                        } else {
                          _selectedCityName = '';
                        }
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      key: ValueKey('$_selectedCityId-$_selectedCityName'), // Force rebuild
                      initialValue: _isOtherCity ? (l10n.otherCity ?? 'Other City') : ((_selectedCityName?.isNotEmpty ?? false) ? _selectedCityName : null),
                      decoration: _buildInputDecoration(theme, l10n.city ?? 'City').copyWith(
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),
                );
              },
            ),

          if (_isOtherCity) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otherCityController,
              decoration: _buildInputDecoration(theme, l10n.enterCityName ?? 'Enter City Name'),
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: _streetController,
            decoration: _buildInputDecoration(theme, l10n.street ?? 'Street'),
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buildingNumberController,
                  decoration: _buildInputDecoration(theme, l10n.buildingNumber ?? 'Building Number'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _apartmentNumberController,
                  decoration: _buildInputDecoration(theme, l10n.apartmentNumber ?? 'Apartment Number'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: _buildInputDecoration(theme, l10n.wizardAddressHint).copyWith(
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 4: Price & Notice ---
  Widget _buildPriceStep(CreateRequestState state, ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.wizardStep4Title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.wizardStep4Subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.wizardContactNotice,
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.wizardContactCheckbox, style: const TextStyle(fontWeight: FontWeight.bold)),
            value: state.hasConfirmedContact,
            activeColor: AppColors.primaryBlue,
            onChanged: (val) {
              if (val != null) {
                context.read<CreateRequestBloc>().add(ConfirmContactNoticeEvent(val));
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.wizardAgreedPriceLabel,
              suffixText: 'EGP',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
               context.read<CreateRequestBloc>().add(EnterAgreedPriceEvent(
                  amount: double.tryParse(val) ?? 0,
               ));
            },
          ),
        ],
      ),
    );
  }

  // --- Step 5: Review ---
  Widget _buildReviewStep(CreateRequestState state, ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.wizardStep5Title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.wizardStep5Subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildSummaryCard(
            theme,
            icon: Icons.design_services,
            title: l10n.wizardSummaryServices,
            content: state.selectedServices.map((e) => e.serviceName).join("، "),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            theme,
            icon: Icons.calendar_today,
            title: l10n.wizardSummarySchedule,
            content: state.appointment != null ? '${state.appointment!.date} ${state.appointment!.time}' : l10n.wizardNotSpecified,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            theme,
            icon: Icons.location_on,
            title: l10n.wizardSummaryLocation,
            content: state.location?.formattedAddress ?? l10n.wizardNotSpecified,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            theme,
            icon: Icons.payments,
            title: l10n.wizardSummaryPrice,
            content: '${state.pricing?.amount ?? 0} EGP',
            contentColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, {required IconData icon, required String title, required String content, Color? contentColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: contentColor ?? theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
