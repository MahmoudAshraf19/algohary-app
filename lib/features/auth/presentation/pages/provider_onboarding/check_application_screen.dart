import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/network/firebase_config.dart';
import 'application_status_screen.dart';

class CheckApplicationScreen extends StatefulWidget {
  const CheckApplicationScreen({super.key});

  @override
  State<CheckApplicationScreen> createState() => _CheckApplicationScreenState();
}

class _CheckApplicationScreenState extends State<CheckApplicationScreen> {
  final _idController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final input = _idController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First, check if input is exactly the document ID
      final docSnapshot = await FirebaseConfig.firestore.collection('provider_applications').doc(input).get();
      
      if (docSnapshot.exists) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ApplicationStatusScreen(applicationId: input)),
          );
        }
        return;
      }

      // Second, if not found by exact doc ID, search by application_id (the 5-digit short ID)
      final appQuery = await FirebaseConfig.firestore
          .collection('provider_applications')
          .where('application_id', isEqualTo: input)
          .limit(1)
          .get();

      if (appQuery.docs.isNotEmpty) {
        final hostId = appQuery.docs.first.id;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ApplicationStatusScreen(applicationId: hostId)),
          );
        }
        return;
      }

      // Third, try searching by user_id
      final querySnapshot = await FirebaseConfig.firestore
          .collection('provider_applications')
          .where('user_id', isEqualTo: input)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final hostId = querySnapshot.docs.first.id;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ApplicationStatusScreen(applicationId: hostId)),
          );
        }
        return;
      }

      // If we reach here, it wasn't found by any method
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noApplicationFoundForId),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('CheckApplicationScreen error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.checkApplication,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              
              Text(
                l10n.checkApplicationDesc,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 40),
              
              Text(
                l10n.enterAppOrPersonalId,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              
              TextField(
                controller: _idController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.enterAppOrPersonalId,
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                onSubmitted: (_) => _isLoading ? null : _checkStatus(),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _checkStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.checkStatus,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
                        ],
                      ),
              ),
              const SizedBox(height: 48),
              
              Text(
                l10n.whereToFindId,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              
              Text(
                l10n.findIdInEmail,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              
              // Decorative Graphic Placeholder
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.email_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'APP-2026-00124',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
