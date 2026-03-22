part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildSubscriptionsSection() {
    return _AdminTableCard<AdminUserRow>(
      title: 'Provider Subscriptions',
      subtitle:
          'Review provider plans, monthly pricing, billing state, and renewal timing.',
      loadingListenable: AdminDashboardState.loadingUsers,
      rowsListenable: AdminDashboardState.users,
      paginationListenable: AdminDashboardState.usersPagination,
      onPageSelected: _loadUsers,
      controls: [
        _DropdownFilter(
          label: 'Plan',
          value: _subscriptionPlanFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All plans'),
            _DropdownOption(value: 'basic', label: 'Basic'),
            _DropdownOption(value: 'professional', label: 'Professional'),
            _DropdownOption(value: 'elite', label: 'Elite'),
          ],
          onChanged: (value) {
            _setSectionState(() => _subscriptionPlanFilter = value);
            unawaited(_loadUsers(1));
          },
        ),
        _DropdownFilter(
          label: 'Billing',
          value: _subscriptionStatusFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All billing states'),
            _DropdownOption(value: 'active', label: 'Active'),
            _DropdownOption(value: 'trialing', label: 'Trialing'),
            _DropdownOption(value: 'past_due', label: 'Past due'),
            _DropdownOption(value: 'inactive', label: 'Inactive'),
            _DropdownOption(value: 'canceled', label: 'Canceled'),
          ],
          onChanged: (value) {
            _setSectionState(() => _subscriptionStatusFilter = value);
            unawaited(_loadUsers(1));
          },
        ),
      ],
      columns: const [
        'Provider',
        'Email',
        'Plan',
        'Monthly Cost',
        'Billing',
        'Renewal',
        'Period End',
        'State',
      ],
      emptyText: 'No provider subscriptions found for this page.',
      summaryBuilder: (items) {
        final professionalMonthlyRevenue = items.fold<double>(0, (sum, item) {
          final tier = item.providerSubscriptionTier.trim().toLowerCase();
          final billingStatus = item.providerSubscriptionStatus
              .trim()
              .toLowerCase();
          if (tier != 'professional' ||
              !_countsTowardSubscriptionRevenue(billingStatus)) {
            return sum;
          }
          return sum + _subscriptionMonthlyPrice(tier);
        });
        final eliteMonthlyRevenue = items.fold<double>(0, (sum, item) {
          final tier = item.providerSubscriptionTier.trim().toLowerCase();
          final billingStatus = item.providerSubscriptionStatus
              .trim()
              .toLowerCase();
          if (tier != 'elite' ||
              !_countsTowardSubscriptionRevenue(billingStatus)) {
            return sum;
          }
          return sum + _subscriptionMonthlyPrice(tier);
        });
        final totalMonthlyRevenue =
            professionalMonthlyRevenue + eliteMonthlyRevenue;
        final active = items
            .where(
              (item) =>
                  item.providerSubscriptionStatus.trim().toLowerCase() ==
                  'active',
            )
            .length;
        final trialing = items
            .where(
              (item) =>
                  item.providerSubscriptionStatus.trim().toLowerCase() ==
                  'trialing',
            )
            .length;
        final professional = items
            .where(
              (item) =>
                  item.providerSubscriptionTier.trim().toLowerCase() ==
                  'professional',
            )
            .length;
        final elite = items
            .where(
              (item) =>
                  item.providerSubscriptionTier.trim().toLowerCase() == 'elite',
            )
            .length;
        return [
          _MetricChipData(label: 'Page providers', value: '${items.length}'),
          _MetricChipData(
            label: 'Active',
            value: '$active',
            color: AppColors.success,
          ),
          _MetricChipData(
            label: 'Total monthly revenue',
            value: _toMoney(totalMonthlyRevenue),
            color: const Color(0xFF0284C7),
          ),
          _MetricChipData(
            label: 'Professional MRR',
            value: _toMoney(professionalMonthlyRevenue),
            color: AppColors.primary,
          ),
          _MetricChipData(
            label: 'Elite MRR',
            value: _toMoney(eliteMonthlyRevenue),
            color: const Color(0xFFF59E0B),
          ),
          _MetricChipData(label: 'Trialing', value: '$trialing'),
          _MetricChipData(label: 'Professional', value: '$professional'),
          _MetricChipData(label: 'Elite', value: '$elite'),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              if (!_isProviderRole(item.role)) return false;
              if (_subscriptionPlanFilter != 'all' &&
                  item.providerSubscriptionTier != _subscriptionPlanFilter) {
                return false;
              }
              final billingStatus = item.providerSubscriptionStatus
                  .trim()
                  .toLowerCase();
              if (_subscriptionStatusFilter != 'all' &&
                  billingStatus != _subscriptionStatusFilter) {
                return false;
              }
              if (query.isEmpty) return true;
              final haystack =
                  '${item.name} ${item.email} ${item.id} ${item.providerSubscriptionTier} '
                          '${item.providerSubscriptionStatus} ${item.providerKycStatus}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        final billingStatus = item.providerSubscriptionStatus.trim().isEmpty
            ? 'inactive'
            : item.providerSubscriptionStatus;
        final renewalLabel = item.providerSubscriptionCancelAtPeriodEnd
            ? 'Ends at period end'
            : 'Auto renew';
        final renewalColor = item.providerSubscriptionCancelAtPeriodEnd
            ? AppColors.warning
            : AppColors.success;
        return [
          DataCell(_cellText(item.name, width: 180)),
          DataCell(
            _cellText(item.email.isEmpty ? '-' : item.email, width: 220),
          ),
          DataCell(
            _Pill(
              text: item.providerSubscriptionTier.isEmpty
                  ? 'Basic'
                  : _titleCase(item.providerSubscriptionTier),
              color: _planColor(item.providerSubscriptionTier),
            ),
          ),
          DataCell(
            _cellText(
              _toMoney(
                _subscriptionMonthlyPrice(item.providerSubscriptionTier),
              ),
            ),
          ),
          DataCell(
            _Pill(
              text: _prettySubscriptionStatus(billingStatus),
              color: _subscriptionStatusColor(billingStatus),
            ),
          ),
          DataCell(_Pill(text: renewalLabel, color: renewalColor)),
          DataCell(
            _cellText(
              _formatDateTime(item.providerSubscriptionPeriodEnd),
              width: 150,
            ),
          ),
          DataCell(
            _Pill(
              text: item.active ? 'Active' : 'Suspended',
              color: item.active ? AppColors.success : AppColors.warning,
            ),
          ),
        ];
      },
    );
  }

  Color _planColor(String tier) {
    switch (tier.trim().toLowerCase()) {
      case 'elite':
        return const Color(0xFFF59E0B);
      case 'professional':
        return AppColors.primary;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _prettySubscriptionStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'trialing':
        return 'Trialing';
      case 'past_due':
        return 'Past due';
      case 'canceled':
      case 'cancelled':
        return 'Canceled';
      case 'active':
        return 'Active';
      default:
        return 'Inactive';
    }
  }

  Color _subscriptionStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'trialing':
        return AppColors.primary;
      case 'past_due':
        return AppColors.warning;
      case 'canceled':
      case 'cancelled':
        return AppColors.danger;
      case 'active':
        return AppColors.success;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _titleCase(String value) {
    final safe = value.trim().toLowerCase();
    if (safe.isEmpty) return '-';
    return safe[0].toUpperCase() + safe.substring(1);
  }

  double _subscriptionMonthlyPrice(String tier) {
    final normalized = tier.trim().toLowerCase();
    for (final plan in SubscriptionPlan.all) {
      if (plan.name.trim().toLowerCase() == normalized) {
        return plan.monthlyPrice;
      }
      if (plan.tier.name.trim().toLowerCase() == normalized) {
        return plan.monthlyPrice;
      }
    }
    return 0;
  }

  bool _countsTowardSubscriptionRevenue(String billingStatus) {
    switch (billingStatus.trim().toLowerCase()) {
      case 'active':
      case 'trialing':
        return true;
      default:
        return false;
    }
  }
}
