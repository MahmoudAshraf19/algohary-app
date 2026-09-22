import 'package:equatable/equatable.dart';
import '../../../data/models/booking_models.dart';

class CreateRequestState extends Equatable {
  final List<SelectedServiceModel> selectedServices;
  final bool hasConfirmedContact;
  final AppointmentModel? appointment;
  final LocationModel? location;
  final PricingModel? pricing;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? newRequestId;

  const CreateRequestState({
    this.selectedServices = const [],
    this.hasConfirmedContact = false,
    this.appointment,
    this.location,
    this.pricing,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.newRequestId,
  });

  CreateRequestState copyWith({
    List<SelectedServiceModel>? selectedServices,
    bool? hasConfirmedContact,
    AppointmentModel? appointment,
    LocationModel? location,
    PricingModel? pricing,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? newRequestId,
  }) {
    return CreateRequestState(
      selectedServices: selectedServices ?? this.selectedServices,
      hasConfirmedContact: hasConfirmedContact ?? this.hasConfirmedContact,
      appointment: appointment ?? this.appointment,
      location: location ?? this.location,
      pricing: pricing ?? this.pricing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage, // We usually want to reset errors to null if not provided
      newRequestId: newRequestId ?? this.newRequestId,
    );
  }

  @override
  List<Object?> get props => [
        selectedServices,
        hasConfirmedContact,
        appointment,
        location,
        pricing,
        isSubmitting,
        isSuccess,
        errorMessage,
        newRequestId,
      ];
}
