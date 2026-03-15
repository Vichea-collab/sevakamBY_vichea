import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/provider.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/provider_card.dart';
import 'provider_detail_page.dart';

class ProviderCategoryPage extends StatefulWidget {
  final ProviderSection section;

  const ProviderCategoryPage({super.key, required this.section});

  @override
  State<ProviderCategoryPage> createState() => _ProviderCategoryPageState();
}

class _ProviderCategoryPageState extends State<ProviderCategoryPage> {
  Future<void> _handleRefresh() async {
    try {
      await ProviderPostState.refreshAllForLookup();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final providers = widget.section.providers;
    final accent = _categoryAccent(widget.section.category);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CategoryHeaderCard(
                    title: widget.section.title,
                    category: widget.section.category,
                    count: providers.length,
                    accent: accent,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  14,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CategoryIntroCard(
                    category: widget.section.category,
                    count: providers.length,
                    accent: accent,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  18,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: providers.isEmpty
                    ? const SliverToBoxAdapter(child: _CategoryEmptyState())
                    : SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final provider = providers[index];
                          final heroTag =
                              'provider-card-${widget.section.category}-${provider.uid}';
                          return ProviderCard(
                            provider: provider,
                            heroTag: heroTag,
                            onDetails: () => Navigator.push(
                              context,
                              slideFadeRoute(
                                ProviderDetailPage(
                                  provider: provider,
                                  heroTag: heroTag,
                                ),
                              ),
                            ),
                          );
                        }, childCount: providers.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.62,
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

class _CategoryHeaderCard extends StatelessWidget {
  final String title;
  final String category;
  final int count;
  final Color accent;
  final VoidCallback onBack;

  const _CategoryHeaderCard({
    required this.title,
    required this.category,
    required this.count,
    required this.accent,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count providers in $category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIntroCard extends StatelessWidget {
  final String category;
  final int count;
  final Color accent;

  const _CategoryIntroCard({
    required this.category,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_categoryIcon(category), color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select a provider to view profile, services, and portfolio.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryEmptyState extends StatelessWidget {
  const _CategoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No providers yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Providers for this category will appear here once they publish their offers.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

Color _categoryAccent(String category) {
  final value = category.trim().toLowerCase();
  if (value.contains('plumb')) return const Color(0xFF0E8AD6);
  if (value.contains('electric')) return const Color(0xFFF59E0B);
  if (value.contains('clean')) return const Color(0xFF10B981);
  if (value.contains('appliance')) return const Color(0xFF6366F1);
  return AppColors.primary;
}

IconData _categoryIcon(String category) {
  final value = category.trim().toLowerCase();
  if (value.contains('clean')) return Icons.cleaning_services_rounded;
  if (value.contains('electric')) return Icons.electrical_services_rounded;
  if (value.contains('plumb')) return Icons.plumbing_rounded;
  if (value.contains('appliance')) return Icons.kitchen_rounded;
  return Icons.handyman_rounded;
}
