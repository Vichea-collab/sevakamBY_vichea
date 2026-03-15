import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/subscription.dart';
import '../../state/subscription_state.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with WidgetsBindingObserver {
  bool _loading = false;
  bool _waitingForCheckout = false;
  String? _lastSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(SubscriptionState.fetchStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForCheckout) {
      _waitingForCheckout = false;
      final sessionId = _lastSessionId;
      _lastSessionId = null;
      _verifyAfterCheckout(sessionId);
    }
  }

  Future<void> _verifyAfterCheckout(String? sessionId) async {
    setState(() => _loading = true);
    await SubscriptionState.refreshAfterCheckout(sessionId: sessionId);
    if (!mounted) return;
    setState(() => _loading = false);

    final tier = SubscriptionState.status.value.tier;
    if (tier != SubscriptionTier.basic) {
      final planName = SubscriptionState.status.value.plan.name;
      AppToast.success(context, 'Your $planName plan is now active.');
    } else {
      AppToast.info(context, 'Payment confirmed. We are finalizing your plan.');
    }
  }

  Future<void> _handleUpgrade(SubscriptionTier tier) async {
    if (tier == SubscriptionTier.basic) return;

    setState(() => _loading = true);
    try {
      final result = await SubscriptionState.createCheckoutSession(tier);
      final url = result.url;
      final sessionId = result.sessionId;
      if (url == null || url.isEmpty) {
        if (mounted) {
          AppToast.error(context, 'Could not create checkout session.');
        }
        return;
      }

      final uri = Uri.parse(url);
      var launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (launched) {
        _waitingForCheckout = true;
        _lastSessionId = sessionId;
        if (mounted) {
          AppToast.success(
            context,
            'Complete payment in browser. Your plan will refresh automatically.',
          );
        }
        unawaited(SubscriptionState.refreshAfterCheckout(sessionId: sessionId));
      } else if (mounted) {
        AppToast.error(context, 'Could not open checkout page.');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Failed to start checkout. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await showAppConfirmDialog(
      context: context,
      icon: Icons.cancel_outlined,
      title: 'Cancel Subscription',
      message:
          'Your plan stays active until the current billing period ends, then it downgrades to Basic.',
      confirmText: 'Cancel Subscription',
      cancelText: 'Keep Plan',
      tone: AppDialogTone.danger,
    );
    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    final success = await SubscriptionState.cancelSubscription();
    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        AppToast.success(
          context,
          'Subscription will cancel at the end of the current period.',
        );
      } else {
        AppToast.error(context, 'Failed to cancel. Try again later.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: ValueListenableBuilder<SubscriptionStatus>(
          valueListenable: SubscriptionState.status,
          builder: (context, status, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                12,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                AppTopBar(
                  title: 'Subscription',
                  actions: [
                    ValueListenableBuilder<bool>(
                      valueListenable: SubscriptionState.loading,
                      builder: (context, isLoading, _) {
                        return IconButton(
                          tooltip: 'Refresh status',
                          onPressed: isLoading || _loading
                              ? null
                              : () => SubscriptionState.fetchStatus(),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  color: AppColors.primary,
                                ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CurrentPlanCard(status: status),
                const SizedBox(height: 22),
                Text(
                  'Plans',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...SubscriptionPlan.all.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlanCard(
                      plan: plan,
                      isCurrentPlan: plan.tier == status.tier,
                      onUpgrade: _loading
                          ? null
                          : () => _handleUpgrade(plan.tier),
                      onCancel:
                          plan.tier == status.tier &&
                              status.tier != SubscriptionTier.basic &&
                              !status.isCanceling
                          ? _handleCancel
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionStatus status;

  const _CurrentPlanCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final plan = status.plan;
    final statusLabel = status.isCanceling
        ? 'Ending soon'
        : (status.isActive ? 'Active' : _prettyStatus(status.status));
    final periodLabel = _periodLabel();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            plan.badgeColor,
            Color.lerp(plan.badgeColor, Colors.black, 0.12)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: plan.badgeColor.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(plan.badgeIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current plan',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.monthlyPrice == 0
                          ? 'Free starter plan'
                          : plan.priceLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Booking usage',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: status.bookingLimit < 0 ? 0 : status.usagePercent,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                status.usagePercent >= 0.9
                    ? const Color(0xFFEF4444)
                    : Colors.white,
              ),
            ),
          ),
          if (periodLabel != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.isCanceling
                              ? 'Access ends at period close'
                              : 'Current billing period',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          periodLabel,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    status.isCanceling ? 'Ends' : 'Renews',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _periodLabel() {
    final start = status.currentPeriodStart;
    final end = status.currentPeriodEnd;
    if (start != null && end != null) {
      return '${_formatShortDate(start)} - ${_formatShortDate(end)}';
    }
    if (end != null) {
      return status.isCanceling
          ? 'Ends ${_formatShortDate(end)}'
          : 'Renews ${_formatShortDate(end)}';
    }
    return null;
  }

  String _prettyStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return 'Inactive';
    return normalized
        .split('_')
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final VoidCallback? onUpgrade;
  final VoidCallback? onCancel;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    this.onUpgrade,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = plan.tier == SubscriptionTier.basic;
    final visibleFeatures = plan.features.take(3).toList(growable: false);
    final highlightStats = <String>[
      plan.bookingLimit < 0
          ? 'Unlimited bookings'
          : '${plan.bookingLimit} bookings/mo',
      '${plan.searchRankMultiplier}x ranking',
      plan.maxPhotos < 0
          ? 'Unlimited portfolio'
          : '${plan.maxPhotos} portfolio photos',
    ];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPlan
              ? plan.badgeColor
              : Theme.of(context).dividerColor,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentPlan
                ? plan.badgeColor.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isCurrentPlan ? 22 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: plan.badgeColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: plan.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(plan.badgeIcon, color: plan.badgeColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            plan.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (isCurrentPlan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: plan.badgeColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Current',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.tagline,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: plan.badgeColor,
                      ),
                    ),
                    if (plan.annualPriceLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          plan.annualPriceLabel,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: plan.badgeColor.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: highlightStats
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: plan.badgeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: plan.badgeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 10),
                ...visibleFeatures.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: plan.badgeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(height: 1.22),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (plan.features.length > visibleFeatures.length) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+${plan.features.length - visibleFeatures.length} more benefits',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (plan.qualityGate != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan.qualityGate!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (plan.bestFor.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Best for: ${plan.bestFor}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                height: 1.2,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isFree || isCurrentPlan)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: Column(
                children: [
                  if (!isCurrentPlan && !isFree)
                    PrimaryButton(
                      label: 'Upgrade to ${plan.name}',
                      icon: Icons.rocket_launch_rounded,
                      onPressed: onUpgrade,
                    ),
                  if (onCancel != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel Subscription'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
