import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import '../../../../bookings/data/models/booking_models.dart';
import '../../../../bookings/data/repositories/bookings_repository.dart';
import '../../../../bookings/presentation/pages/request_details_screen.dart';
import '../../../../bookings/presentation/bloc/request_details/request_details_bloc.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final BookingsRepository _repository = BookingsRepository();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.navBookings ?? 'Bookings',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthSuccess) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final user = state.user;
          // In a real app we might determine if the user is a provider or not.
          // For now we'll assume they are a customer (isProvider: false).
          return StreamBuilder<List<ServiceRequestModel>>(
            stream: _repository.streamUserRequests(user.id, isProvider: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                debugPrint('BookingsTab Error: ${snapshot.error}');
                return const Center(child: Text('حدث خطأ أثناء تحميل الطلبات'));
              }
              
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return const Center(child: Text('No bookings found.'));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        'Booking #${request.id.substring(0, 6)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Status: ${request.status.value}'),
                          Text('Date: ${request.appointment.date} at ${request.appointment.time}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (_) => RequestDetailsBloc(bookingsRepository: _repository),
                              child: RequestDetailsScreen(
                                requestId: request.id,
                                currentUserId: user.id,
                                isProvider: false, // For now, assume customer view
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
