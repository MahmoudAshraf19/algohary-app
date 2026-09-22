import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:algohary_project/features/auth/data/models/user_model.dart';
import '../../data/models/service_model.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../data/repositories/provider_repository.dart';
import '../../../chat/data/services/chat_service.dart';
import '../../../chat/presentation/pages/chat_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/features/bookings/presentation/pages/create_request_wizard_screen.dart';
import 'package:algohary_project/features/bookings/presentation/bloc/create_request/create_request_bloc.dart';
import 'package:algohary_project/features/bookings/data/repositories/bookings_repository.dart';
class ProviderProfileScreen extends StatefulWidget {
  final UserModel provider;
  final String? heroTag;

  const ProviderProfileScreen({
    super.key,
    required this.provider,
    this.heroTag,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _repository = ProviderRepository();

  Map<String, String>? _categoryDetails;
  String? _governorateName;
  List<String> _cityNames = [];
  List<Map<String, String>> _servicesDetails = [];

  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final langCode = Localizations.localeOf(context).languageCode;

    final futures = <Future>[];

    if (widget.provider.categoryId != null) {
      futures.add(
        _repository
            .getCategoryDetails(widget.provider.categoryId!, langCode)
            .then((val) {
              if (mounted) _categoryDetails = val;
            }),
      );
    }

    if (widget.provider.governorateId != null) {
      futures.add(
        _repository
            .getGovernorateName(widget.provider.governorateId!, langCode)
            .then((val) {
              if (mounted) _governorateName = val;
            }),
      );
    }

    if (widget.provider.cities != null && widget.provider.cities!.isNotEmpty) {
      futures.add(
        _repository.getCityNames(widget.provider.cities!, langCode).then((val) {
          if (mounted) _cityNames = val;
        }),
      );
    }

    if (widget.provider.services != null &&
        widget.provider.services!.isNotEmpty) {
      futures.add(
        _repository.getServiceDetails(widget.provider.services!, langCode).then(
          (val) {
            if (mounted) _servicesDetails = val;
          },
        ),
      );
    }

    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    // Accent background for icons and avatar
    final accentBg = isDark
        ? primaryColor.withValues(alpha: 0.15)
        : const Color(0xFFFFF3B0);
    // Border color
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          l10n.providerProfile ?? "Provider Profile",
          style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurface),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: onSurface),
            onSelected: (value) {
              if (value == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.reportProvider ?? 'Report')),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text(l10n.reportProvider ?? 'Report'),
              ),
            ],
          ),
        ],
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Provider Avatar
              Hero(
                tag: widget.heroTag ?? 'provider_${widget.provider.id}',
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentBg,
                    border: Border.all(color: surfaceColor, width: 4),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.provider.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Provider Name
              Text(
                '${widget.provider.firstName} ${widget.provider.lastName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Primary Category
              if (_categoryDetails != null || _isLoading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_categoryDetails != null &&
                        _categoryDetails!['icon_url'] != null &&
                        _categoryDetails!['icon_url']!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: CachedNetworkImage(
                          imageUrl: _categoryDetails!['icon_url']!,
                          width: 16,
                          height: 16,
                          color: primaryColor,
                          errorWidget: (context, url, error) =>
                              Icon(Icons.build, size: 16, color: primaryColor),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Icon(Icons.build, size: 16, color: primaryColor),
                      ),
                    Text(
                      _isLoading
                          ? 'جاري التحميل...'
                          : (_categoryDetails?['name'] ?? ''),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              ),
                            );

                            final chatService = ChatService();
                            final conversationId = await chatService
                                .createOrGetConversation(widget.provider.id);

                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    conversationId: conversationId,
                                    recipientName:
                                        '${widget.provider.firstName} ${widget.provider.lastName}',
                                    recipientAvatar: widget.provider.imageUrl,
                                    recipientId: widget.provider.id,
                                  ),
                                ),
                              );
                            }
                          } catch (e, stackTrace) {
                            print('🚨 Error opening chat: $e');
                            print(stackTrace);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error: ${e.toString().contains("logged in") ? "Please login to send messages." : "Could not open chat."}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          color: primaryColor,
                        ),
                        label: Text(
                          l10n.messageProvider ?? "Message",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                          if (currentUserId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please login to request a service')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (_) => CreateRequestBloc(
                                  bookingsRepository: BookingsRepository(),
                                ),
                                child: CreateRequestWizardScreen(
                                  provider: widget.provider,
                                  userId: currentUserId,
                                ),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.handyman,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          l10n.requestService ?? "Request Service",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Contact Information
              _buildContactRow(
                icon: Icons.email_outlined,
                text: widget.provider.email,
                color: onSurface,
              ),
              const SizedBox(height: 16),
              _buildContactRow(
                icon: Icons.phone_outlined,
                text: widget.provider.phone,
                color: onSurface,
                isLtr: true,
              ),

              const SizedBox(height: 32),

              // About Section
              _buildSection(
                title: l10n.aboutProvider ?? "About",
                icon: Icons.person_outline,
                color: primaryColor,
                borderColor: borderColor,
                surfaceColor: surfaceColor,
                child: Text(
                  widget.provider.about?.isNotEmpty == true
                      ? widget.provider.about!
                      : (l10n.aboutProvider ??
                            'Professional service provider committed to delivering high-quality work and customer satisfaction.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),

              // Category Section
              if (_categoryDetails != null)
                _buildSection(
                  title: l10n.category ?? "Category",
                  icon: Icons.grid_view_outlined,
                  color: primaryColor,
                  borderColor: borderColor,
                  surfaceColor: surfaceColor,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_categoryDetails!['icon_url'] != null &&
                            _categoryDetails!['icon_url']!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CachedNetworkImage(
                              imageUrl: _categoryDetails!['icon_url']!,
                              width: 20,
                              height: 20,
                              color: primaryColor,
                              errorWidget: (context, url, error) => Icon(
                                Icons.build,
                                size: 20,
                                color: primaryColor,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.build,
                              size: 20,
                              color: primaryColor,
                            ),
                          ),
                        Text(
                          _categoryDetails!['name'] ?? '',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Services Section
              if (_servicesDetails.isNotEmpty || _isLoading)
                _buildExpandableSection(
                  title: l10n.services ?? "Services",
                  icon: Icons.build_outlined,
                  color: primaryColor,
                  borderColor: borderColor,
                  surfaceColor: surfaceColor,
                  children: _isLoading
                      ? List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.handyman,
                                    size: 20,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'خدمة تجريبية للتحميل',
                                    style: TextStyle(
                                      color: onSurface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _servicesDetails.map((service) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child:
                                      service['icon_url'] != null &&
                                          service['icon_url']!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: service['icon_url']!,
                                          width: 20,
                                          height: 20,
                                          color: primaryColor,
                                          errorWidget: (context, url, error) =>
                                              Icon(
                                                Icons.handyman,
                                                size: 20,
                                                color: primaryColor,
                                              ),
                                        )
                                      : Icon(
                                          Icons.handyman,
                                          size: 20,
                                          color: primaryColor,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    service['name'] ?? '',
                                    style: TextStyle(
                                      color: onSurface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),

              // Location Section
              _buildSection(
                title: l10n.location ?? "Location",
                icon: Icons.location_on_outlined,
                color: primaryColor,
                borderColor: borderColor,
                surfaceColor: surfaceColor,
                isLast: true,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.map_outlined, color: primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _governorateName ?? '',
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (_cityNames.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _cityNames.join(', '),
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: onSurface.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required Color color,
    bool isLtr = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textDirection: isLtr ? TextDirection.ltr : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required Color surfaceColor,
    required Widget child,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required Color surfaceColor,
    required List<Widget> children,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 20,
            ),
            title: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
