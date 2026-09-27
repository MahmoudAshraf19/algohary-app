import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:algohary_project/features/subscriptions/presentation/bloc/subscription_bloc.dart';
import 'package:algohary_project/features/subscriptions/presentation/bloc/subscription_event.dart';
import 'package:algohary_project/features/subscriptions/presentation/bloc/subscription_state.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_event.dart';
import 'package:algohary_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  final bool isForced;
  const SubscriptionPlanScreen({Key? key, this.isForced = false}) : super(key: key);

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  SubscriptionPlanModel? _selectedPlan;

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(FetchSubscriptionPlans());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // We get current user's active plan id
    String? currentPlanId;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      currentPlanId = authState.user.subscription.plan;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.primaryBlue,
        ),
        // Hide back button if forced
        automaticallyImplyLeading: !widget.isForced,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionActivated) {
            // Refetch user data so that the AuthBloc has the new subscription plan ID
            context.read<AuthBloc>().add(CheckAuthStatus());
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Subscription activated successfully")),
            );
            if (widget.isForced) {
              Navigator.of(context).pushReplacementNamed('/provider_dashboard'); // Assume route exists or redirect via SplashScreen
            } else {
              Navigator.of(context).pop(true);
            }
          } else if (state is SubscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.chooseBusinessPlan,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.primaryBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.chooseBusinessPlanDesc,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (widget.isForced) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.localeName == 'ar' 
                                      ? "انتهت صلاحية اشتراكك، يرجى اختيار خطة جديدة للمتابعة." 
                                      : "Your subscription has expired, please select a new plan to continue.",
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state is SubscriptionLoading || state is SubscriptionInitial || state is SubscriptionActivating)
                    Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          final mockPlan = SubscriptionPlanModel(
                            id: 'mock_$index',
                            name: 'Loading Plan Name',
                            description: 'Description goes here',
                            expiryDay: '30',
                            price: '99',
                            type: 'paid',
                            image: '',
                            isEnable: true,
                            itemLimit: '0',
                            orderLimit: '0',
                            features: {},
                            planPoints: [],
                            place: '0',
                          );
                          return _buildSubscriptionPlanWidget(
                            mockPlan,
                            currentPlanId,
                            isDark,
                            l10n,
                            theme,
                          );
                        },
                      ),
                    )
                  else if (state is SubscriptionLoaded)
                    state.plans.isEmpty
                        ? SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(l10n.planNotFound),
                            ),
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: state.plans.length,
                            itemBuilder: (context, index) {
                              final plan = state.plans[index];
                              return _buildSubscriptionPlanWidget(
                                plan,
                                currentPlanId,
                                isDark,
                                l10n,
                                theme,
                              );
                            },
                          )
                  else if (state is SubscriptionError)
                    Center(child: Text(state.message)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionPlanWidget(
    SubscriptionPlanModel plan,
    String? currentPlanId,
    bool isDark,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    bool isSelected = _selectedPlan?.id == plan.id;
    bool isActive = currentPlanId == plan.id;

    Color containerColor = isSelected
        ? (isDark ? Colors.white : AppColors.primaryBlue)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    Color textColor = isSelected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black);

    Color subTextColor = isSelected
        ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
        : (isDark ? Colors.grey[400]! : Colors.grey[600]!);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
          color: containerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        plan.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image, size: 50, color: subTextColor),
                      ),
                    )
                  else
                    Icon(Icons.business_center, size: 50, color: subTextColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          plan.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.active,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.type == 'free' ? l10n.free : "\$${plan.price}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.expiryDay == '-1'
                        ? l10n.lifetime
                        : "${plan.expiryDay} ${l10n.days}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? (isDark ? AppColors.primaryBlue : AppColors.orange)
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (isActive) {
                      // Already active, do nothing or show message
                      return;
                    }
                    if (_selectedPlan?.id == plan.id) {
                      _showConfirmationDialog(context, plan, l10n);
                    } else {
                      setState(() {
                        _selectedPlan = plan;
                      });
                    }
                  },
                  child: Text(
                    isActive
                        ? l10n.active
                        : (isSelected ? l10n.renew : l10n.selectPlan),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showConfirmationDialog(BuildContext context, SubscriptionPlanModel plan, AppLocalizations l10n) {
    DateTime now = DateTime.now();
    DateTime? endDate;
    if (plan.expiryDay != '-1') {
      int days = int.tryParse(plan.expiryDay) ?? 0;
      endDate = now.add(Duration(days: days));
    }
    
    String startDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String endDateStr = endDate != null 
        ? "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}"
        : l10n.lifetime;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.autorenew_rounded,
                    color: AppColors.primaryBlue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.renew,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.renewSubscriptionConfirm(startDateStr, endDateStr),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          l10n.btnCancel,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _processPaymentAndActivate(plan, l10n);
                        },
                        child: Text(
                          l10n.submit,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processPaymentAndActivate(SubscriptionPlanModel plan, AppLocalizations l10n) {
    // Implement Mock Payment or integrate your Payment Gateway here.
    // For now, directly activate.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      final userId = authState.user.id;
      context.read<SubscriptionBloc>().add(ActivateSubscription(
            userId: userId,
            plan: plan,
            notificationTitle: l10n.subscriptionActivatedTitle,
            notificationBody: l10n.subscriptionActivatedBody(plan.name),
          ));
    }
  }
}
