import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_bloc.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_event.dart';
import 'package:algohary_project/core/services/location_service.dart';
import '../pages/map_picker_screen.dart';

class LocationBottomSheet extends StatefulWidget {
  const LocationBottomSheet({super.key});

  /// Helper to show this bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationBottomSheet(),
    );
  }

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  final _locationService = LocationService();
  bool _isLoading = false;

  Future<void> _handleAllowLocation(BuildContext context) async {
    setState(() => _isLoading = true);
    
    try {
      // Add a timeout just in case it hangs on web
      final address = await _locationService.getCurrentAddress().timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );
      
      if (!context.mounted) return;
      
      if (address != null) {
        context.read<LocationBloc>().add(
          SetLocation(latitude: 0.0, longitude: 0.0, address: address),
        );
        Navigator.pop(context); // Close bottom sheet
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.homeLocationError)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.homeLocationError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image
          Image.asset(
            'assets/images/access_loction.png',
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            l10n.locationAccessTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            l10n.locationAccessDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Allow Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleAllowLocation(context),
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.location_on),
              label: Text(_isLoading ? '' : l10n.locationAccessAllowBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Map Picker Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapPickerScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.locationAccessMapBtn),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Not Now Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(l10n.locationAccessNotNowBtn),
            ),
          ),
        ],
      ),
    );
  }
}
