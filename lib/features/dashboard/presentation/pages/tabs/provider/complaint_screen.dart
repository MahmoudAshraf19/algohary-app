import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../../bookings/data/models/booking_models.dart';
import '../../../../../bookings/data/repositories/bookings_repository.dart';

class ComplaintScreen extends StatefulWidget {
  final ServiceRequestModel order;
  const ComplaintScreen({super.key, required this.order});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (_reasonController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    
    final authState = context.read<AuthBloc>().state;
    final user = (authState is AuthSuccess) ? authState.user : null;
    
    if (user == null) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }
    
    try {
      final complaint = ComplaintModel(
        id: '',
        bookingId: widget.order.id,
        submittedBy: user!.userType == 'provider' ? 'PROVIDER' : 'USER',
        submittedById: user.id,
        againstId: user.userType == 'provider' ? widget.order.userId : widget.order.providerId,
        reason: _reasonController.text.trim(),
        description: _descriptionController.text.trim(),
        status: 'UNDER_REVIEW',
        createdAt: DateTime.now(),
      );

      await BookingsRepository().submitComplaint(complaint);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully. We will review it shortly.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.complaintTitle ?? 'Submit Complaint', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #ORD-${widget.order.id.substring(0, 5).toUpperCase()}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.complaintReason ?? 'Reason',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'e.g., Customer did not show up',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.complaintDescription ?? 'Description',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please provide more details...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.submit ?? 'Submit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
