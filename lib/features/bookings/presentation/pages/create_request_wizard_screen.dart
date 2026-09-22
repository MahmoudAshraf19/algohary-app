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
  final _addressController = TextEditingController();

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

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _addressController.dispose();
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
      if (_addressController.text.isEmpty) {
        _showError(l10n.wizardProvideLocation);
        canProceed = false;
      } else {
        context.read<CreateRequestBloc>().add(SelectLocationEvent(
          LocationModel(
            latitude: 30.0,
            longitude: 31.0,
            geohash: 'g',
            formattedAddress: _addressController.text,
            details: AddressDetailsModel(
              buildingNumber: '1',
              floor: '1',
              apartmentNumber: '1',
              street: 'Test',
              district: 'Test',
              city: 'Test',
              landmark: 'Test',
              additionalInstructions: '',
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
          const SizedBox(height: 32),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.wizardAddressHint,
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
