part of '../pages/admin_dashboard_page.dart';

class _OverviewKpiGrid extends StatelessWidget {
  final Map<String, num> kpis;

  const _OverviewKpiGrid({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final adminCount = _overviewAdminCount(kpis);
    final cards = [
      _KpiData(
        label: 'Users',
        value: '${_intValue(kpis['users'])}',
        icon: Icons.group_rounded,
      ),
      _KpiData(
        label: 'Admins',
        value: '$adminCount',
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _KpiData(
        label: 'Finders',
        value: '${_intValue(kpis['finders'])}',
        icon: Icons.person_search_rounded,
        color: const Color(0xFF14B8A6),
      ),
      _KpiData(
        label: 'Providers',
        value: '${_intValue(kpis['providers'])}',
        icon: Icons.handyman_rounded,
      ),
      _KpiData(
        label: 'Orders',
        value: '${_intValue(kpis['orders'])}',
        icon: Icons.receipt_long_rounded,
      ),
      _KpiData(
        label: 'Open Finder Requests',
        value: '${_intValue(kpis['activeFinderRequests'])}',
        icon: Icons.assignment_rounded,
      ),
      _KpiData(
        label: 'Open Provider Offers',
        value: '${_intValue(kpis['activeProviderPosts'])}',
        icon: Icons.campaign_rounded,
      ),
      _KpiData(
        label: 'Open Tickets',
        value: '${_intValue(kpis['openHelpTickets'])}',
        icon: Icons.support_agent_rounded,
      ),
      _KpiData(
        label: 'KYC Pending',
        value: '${_intValue(kpis['pendingKycProviders'])}',
        icon: Icons.pending_actions_rounded,
      ),
      _KpiData(
        label: 'KYC Approved',
        value: '${_intValue(kpis['verifiedProviders'])}',
        icon: Icons.verified_user_rounded,
      ),
      _KpiData(
        label: 'Plus',
        value: '${_intValue(kpis['professionalProviders'])}',
        icon: Icons.workspace_premium_rounded,
      ),
      _KpiData(
        label: 'Pro',
        value: '${_intValue(kpis['eliteProviders'])}',
        icon: Icons.diamond_rounded,
      ),
      _KpiData(
        label: 'Total Revenue',
        value: _toMoney(
          _numValue(kpis['totalRevenue']) != 0
              ? _numValue(kpis['totalRevenue'])
              : _numValue(kpis['completedRevenue']),
        ),
        icon: Icons.attach_money_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 760
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 2 ? 1.5 : 1.8,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF8FAFF),
                border: Border.all(color: const Color(0xFFDDE6F8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: card.color.withValues(alpha: 0.12),
                    ),
                    child: Icon(card.icon, color: card.color, size: 44),
                  ),
                  const Spacer(),
                  Text(
                    card.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

int _overviewAdminCount(Map<String, num> kpis) {
  final explicit = _firstAvailableKpiInt(
    kpis,
    const ['admins', 'adminsCount', 'adminUsers', 'totalAdmins'],
  );
  if (explicit != null) return explicit;

  final totalUsers = _firstAvailableKpiInt(
    kpis,
    const ['users', 'totalUsers'],
  );
  final finders = _firstAvailableKpiInt(
    kpis,
    const ['finders', 'finderUsers'],
  );
  final providers = _firstAvailableKpiInt(
    kpis,
    const ['providers', 'providerUsers'],
  );
  final legacyUsers = _firstAvailableKpiInt(
    kpis,
    const ['legacyUsers', 'usersLegacy'],
  );

  if (totalUsers == null) return 0;
  final inferred = totalUsers - (finders ?? 0) - (providers ?? 0) - (legacyUsers ?? 0);
  if (inferred < 0) return 0;
  return inferred;
}

int? _firstAvailableKpiInt(Map<String, num> kpis, List<String> keys) {
  for (final key in keys) {
    final value = kpis[key];
    if (value == null) continue;
    return _intValue(value);
  }
  return null;
}

class _StatusBoard extends StatelessWidget {
  final Map<String, int> status;

  const _StatusBoard({required this.status});

  @override
  Widget build(BuildContext context) {
    final chips = [
      _MetricChipData(
        label: 'Booked',
        value: '${status['booked'] ?? 0}',
        color: AppColors.warning,
      ),
      _MetricChipData(
        label: 'On the way',
        value: '${status['on_the_way'] ?? 0}',
        color: AppColors.primary,
      ),
      _MetricChipData(
        label: 'Started',
        value: '${status['started'] ?? 0}',
        color: const Color(0xFF0284C7),
      ),
      _MetricChipData(
        label: 'Completed',
        value: '${status['completed'] ?? 0}',
        color: AppColors.success,
      ),
      _MetricChipData(
        label: 'Cancelled',
        value: '${status['cancelled'] ?? 0}',
        color: AppColors.danger,
      ),
      _MetricChipData(
        label: 'Declined',
        value: '${status['declined'] ?? 0}',
        color: const Color(0xFFE11D48),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order status health',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (item) => _Pill(
                    text: '${item.label}: ${item.value}',
                    color: item.color,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _GlobalSearchPanel extends StatelessWidget {
  final AdminGlobalSearchResult result;
  final ValueChanged<AdminSearchItem> onTap;

  const _GlobalSearchPanel({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8E3F6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Global results for "${result.query}"',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Pill(
                  text: '${result.total} matches',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...result.groups.map((group) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...group.items.map(
                      (item) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onTap(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCE6F7)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _searchSectionIcon(item.section),
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (item.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _UndoHistoryCard extends StatelessWidget {
  final bool loading;
  final List<AdminUndoHistoryRow> items;
  final AdminPagination pagination;
  final String selectedState;
  final ValueChanged<String> onStateChanged;
  final Future<void> Function(int page) onPageSelected;
  final Future<void> Function(AdminUndoHistoryRow row) onUndo;

  const _UndoHistoryCard({
    required this.loading,
    required this.items,
    required this.pagination,
    required this.selectedState,
    required this.onStateChanged,
    required this.onPageSelected,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Undo history',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedState,
                  isExpanded: true,
                  dropdownColor: _adminFieldFillColor,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: _adminFieldDecoration(
                    labelText: 'State',
                    dense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All states')),
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(value: 'used', child: Text('Used')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    onStateChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track reversible actions and restore items while undo is still valid.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (loading && items.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 10),
          if (loading && items.isEmpty)
            const SizedBox(
              height: 260,
              child: Center(
                child: _AdminLoadingPanel(
                  title: 'Loading undo history',
                  message: 'Fetching recent reversible actions.',
                ),
              ),
            )
          else if (items.isEmpty)
            Text(
              'No undo actions found.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            ...items.map((item) {
              final stateColor = _undoStateColor(item.state);
              final target = item.targetLabel.isEmpty
                  ? item.docPath
                  : item.targetLabel;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE6F8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_prettyUndoActionType(item.actionType)} • ${target.isEmpty ? item.id : target}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          text: _prettyStatus(item.state),
                          color: stateColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.reason.isEmpty ? 'No reason provided.' : item.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Created: ${_formatDateTime(item.createdAt)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Expires: ${_formatDateTime(item.expiresAt)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (item.usedAt != null)
                          Text(
                            'Used: ${_formatDateTime(item.usedAt)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    if (item.canUndo) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => onUndo(item),
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Undo now'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 6),
          Text(
            'Page ${pagination.page} • ${items.length} items',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _CompactPager(
            page: pagination.page,
            totalPages: pagination.totalPages,
            loading: loading,
            onPageSelected: onPageSelected,
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<_ActivityItem> items;
  final String emptyText;

  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            Column(
              children: items
                  .take(7)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCE6F7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.trailing,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

IconData _searchSectionIcon(String section) {
  switch (section.trim().toLowerCase()) {
    case 'users':
      return Icons.group_rounded;
    case 'orders':
      return Icons.receipt_long_rounded;
    case 'posts':
      return Icons.campaign_rounded;
    case 'tickets':
      return Icons.support_agent_rounded;
    case 'services':
      return Icons.handyman_rounded;
    case 'broadcasts':
      return Icons.campaign_rounded;
    default:
      return Icons.search_rounded;
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String trailing;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
}
