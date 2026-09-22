import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceRequestStatus {
  pendingProviderApproval,
  changeProposed,
  pendingProviderConfirmation,
  approved,
  rejected,
  cancelledByUser,
  cancelledByProvider,
  inProgress,
  completed,
  expired,
}

extension ServiceRequestStatusExt on ServiceRequestStatus {
  String get value {
    switch (this) {
      case ServiceRequestStatus.pendingProviderApproval: return 'PENDING_PROVIDER_APPROVAL';
      case ServiceRequestStatus.changeProposed: return 'CHANGE_PROPOSED';
      case ServiceRequestStatus.pendingProviderConfirmation: return 'PENDING_PROVIDER_CONFIRMATION';
      case ServiceRequestStatus.approved: return 'APPROVED';
      case ServiceRequestStatus.rejected: return 'REJECTED';
      case ServiceRequestStatus.cancelledByUser: return 'CANCELLED_BY_USER';
      case ServiceRequestStatus.cancelledByProvider: return 'CANCELLED_BY_PROVIDER';
      case ServiceRequestStatus.inProgress: return 'IN_PROGRESS';
      case ServiceRequestStatus.completed: return 'COMPLETED';
      case ServiceRequestStatus.expired: return 'EXPIRED';
    }
  }

  static ServiceRequestStatus fromString(String status) {
    switch (status) {
      case 'PENDING_PROVIDER_APPROVAL': return ServiceRequestStatus.pendingProviderApproval;
      case 'CHANGE_PROPOSED': return ServiceRequestStatus.changeProposed;
      case 'PENDING_PROVIDER_CONFIRMATION': return ServiceRequestStatus.pendingProviderConfirmation;
      case 'APPROVED': return ServiceRequestStatus.approved;
      case 'REJECTED': return ServiceRequestStatus.rejected;
      case 'CANCELLED_BY_USER': return ServiceRequestStatus.cancelledByUser;
      case 'CANCELLED_BY_PROVIDER': return ServiceRequestStatus.cancelledByProvider;
      case 'IN_PROGRESS': return ServiceRequestStatus.inProgress;
      case 'COMPLETED': return ServiceRequestStatus.completed;
      case 'EXPIRED': return ServiceRequestStatus.expired;
      default: return ServiceRequestStatus.pendingProviderApproval;
    }
  }
}

class SelectedServiceModel {
  final String serviceId;
  final String serviceName;
  final String categoryName;
  final int quantity;

  SelectedServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.categoryName,
    required this.quantity,
  });

  factory SelectedServiceModel.fromJson(Map<String, dynamic> json) {
    return SelectedServiceModel(
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      categoryName: json['categoryName'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'categoryName': categoryName,
      'quantity': quantity,
    };
  }
}

class AppointmentModel {
  final String date;
  final String time;
  final DateTime? timestamp;
  final String timezone;

  AppointmentModel({
    required this.date,
    required this.time,
    this.timestamp,
    required this.timezone,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      timestamp: json['timestamp'] != null ? (json['timestamp'] as Timestamp).toDate() : null,
      timezone: json['timezone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'time': time,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'timezone': timezone,
    };
  }
}

class AddressDetailsModel {
  final String buildingNumber;
  final String floor;
  final String apartmentNumber;
  final String street;
  final String district;
  final String city;
  final String landmark;
  final String additionalInstructions;

  AddressDetailsModel({
    required this.buildingNumber,
    required this.floor,
    required this.apartmentNumber,
    required this.street,
    required this.district,
    required this.city,
    required this.landmark,
    required this.additionalInstructions,
  });

  factory AddressDetailsModel.fromJson(Map<String, dynamic> json) {
    return AddressDetailsModel(
      buildingNumber: json['buildingNumber'] ?? '',
      floor: json['floor'] ?? '',
      apartmentNumber: json['apartmentNumber'] ?? '',
      street: json['street'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      landmark: json['landmark'] ?? '',
      additionalInstructions: json['additionalInstructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buildingNumber': buildingNumber,
      'floor': floor,
      'apartmentNumber': apartmentNumber,
      'street': street,
      'district': district,
      'city': city,
      'landmark': landmark,
      'additionalInstructions': additionalInstructions,
    };
  }
}

class LocationModel {
  final double latitude;
  final double longitude;
  final String geohash;
  final String formattedAddress;
  final AddressDetailsModel details;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.formattedAddress,
    required this.details,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      geohash: json['geohash'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      details: AddressDetailsModel.fromJson(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'formattedAddress': formattedAddress,
      'details': details.toJson(),
    };
  }
}

class PricingModel {
  final double amount;
  final String currency;
  final String priceSource;

  PricingModel({
    required this.amount,
    required this.currency,
    required this.priceSource,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EGP',
      priceSource: json['priceSource'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'priceSource': priceSource,
    };
  }
}

class RequestActionModel {
  final String type;
  final String performedBy;
  final String performedById;
  final DateTime performedAt;

  RequestActionModel({
    required this.type,
    required this.performedBy,
    required this.performedById,
    required this.performedAt,
  });

  factory RequestActionModel.fromJson(Map<String, dynamic> json) {
    return RequestActionModel(
      type: json['type'] ?? '',
      performedBy: json['performedBy'] ?? '',
      performedById: json['performedById'] ?? '',
      performedAt: json['performedAt'] != null 
          ? (json['performedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'performedBy': performedBy,
      'performedById': performedById,
      'performedAt': Timestamp.fromDate(performedAt),
    };
  }
}

class ServiceRequestModel {
  final String id;
  final String userId;
  final String providerId;
  final ServiceRequestStatus status;
  final List<SelectedServiceModel> selectedServices;
  final AppointmentModel appointment;
  final LocationModel location;
  final PricingModel pricing;
  final Map<String, dynamic>? originalRequest;
  final Map<String, dynamic>? currentProposal;
  final int revisionNumber;
  final RequestActionModel lastAction;
  final bool userConfirmedProviderContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequestModel({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.status,
    required this.selectedServices,
    required this.appointment,
    required this.location,
    required this.pricing,
    this.originalRequest,
    this.currentProposal,
    required this.revisionNumber,
    required this.lastAction,
    required this.userConfirmedProviderContact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json, String docId) {
    var servicesList = json['selectedServices'] as List? ?? [];
    return ServiceRequestModel(
      id: json['id'] ?? docId,
      userId: json['userId'] ?? '',
      providerId: json['providerId'] ?? '',
      status: ServiceRequestStatusExt.fromString(json['status'] ?? ''),
      selectedServices: servicesList.map((s) => SelectedServiceModel.fromJson(s)).toList(),
      appointment: AppointmentModel.fromJson(json['appointment'] ?? {}),
      location: LocationModel.fromJson(json['location'] ?? {}),
      pricing: PricingModel.fromJson(json['pricing'] ?? {}),
      originalRequest: json['originalRequest'],
      currentProposal: json['currentProposal'],
      revisionNumber: json['revisionNumber'] ?? 0,
      lastAction: RequestActionModel.fromJson(json['lastAction'] ?? {}),
      userConfirmedProviderContact: json['userConfirmedProviderContact'] ?? false,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'providerId': providerId,
      'status': status.value,
      'selectedServices': selectedServices.map((s) => s.toJson()).toList(),
      'appointment': appointment.toJson(),
      'location': location.toJson(),
      'pricing': pricing.toJson(),
      'originalRequest': originalRequest,
      'currentProposal': currentProposal,
      'revisionNumber': revisionNumber,
      'lastAction': lastAction.toJson(),
      'userConfirmedProviderContact': userConfirmedProviderContact,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class RequestRevisionModel {
  final int revisionNumber;
  final String proposedBy;
  final String proposedById;
  final Map<String, dynamic> changes;
  final String reason;
  final String status;
  final DateTime createdAt;

  RequestRevisionModel({
    required this.revisionNumber,
    required this.proposedBy,
    required this.proposedById,
    required this.changes,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory RequestRevisionModel.fromJson(Map<String, dynamic> json) {
    return RequestRevisionModel(
      revisionNumber: json['revisionNumber'] ?? 1,
      proposedBy: json['proposedBy'] ?? '',
      proposedById: json['proposedById'] ?? '',
      changes: json['changes'] ?? {},
      reason: json['reason'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revisionNumber': revisionNumber,
      'proposedBy': proposedBy,
      'proposedById': proposedById,
      'changes': changes,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class StatusHistoryModel {
  final String status;
  final String performedBy;
  final String performedById;
  final String message;
  final DateTime createdAt;

  StatusHistoryModel({
    required this.status,
    required this.performedBy,
    required this.performedById,
    required this.message,
    required this.createdAt,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryModel(
      status: json['status'] ?? '',
      performedBy: json['performedBy'] ?? '',
      performedById: json['performedById'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'performedBy': performedBy,
      'performedById': performedById,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
