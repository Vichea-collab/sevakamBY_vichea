part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildOverviewSection() {
    final query = _searchQuery.trim().toLowerCase();
    return ValueListenableBuilder<bool>(
      valueListenable: AdminDashboardState.loadingOverview,
      builder: (context, loading, _) {
        return ValueListenableBuilder<AdminOverview>(
          valueListenable: AdminDashboardState.overview,
          builder: (context, row, _) {
            final kpis = row.kpis;
            final orderStatus = row.orderStatus;

            final recentOrders = row.recentOrders
                .where((item) {
                  if (query.isEmpty) return true;
                  final haystack =
                      '${item.serviceName} ${item.finderName} ${item.providerName} ${item.status}'
                          .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);

            final recentUsers = row.recentUsers
                .where((item) {
                  if (query.isEmpty) return true;
                  final haystack = '${item.name} ${item.email} ${item.role}'
                      .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);

            final recentPosts = row.recentPosts
                .where((item) {
                  if (query.isEmpty) return true;
                  final haystack =
                      '${item.ownerName} ${item.type} ${item.category} ${item.service} ${item.status}'
                          .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);
            final hasOverviewData =
                row.kpis.isNotEmpty ||
                row.orderStatus.isNotEmpty ||
                row.recentOrders.isNotEmpty ||
                row.recentUsers.isNotEmpty ||
                row.recentPosts.isNotEmpty;

            if (loading && !hasOverviewData) {
              return const SizedBox(
                height: 420,
                child: Center(
                  child: _AdminLoadingPanel(
                    title: 'Loading overview',
                    message: 'Preparing KPIs and recent activity feed.',
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                _OverviewKpiGrid(kpis: kpis),
                const SizedBox(height: 14),
                _StatusBoard(status: orderStatus),
                const SizedBox(height: 14),
                ValueListenableBuilder<bool>(
                  valueListenable: AdminDashboardState.loadingUndoHistory,
                  builder: (context, historyLoading, _) {
                    return ValueListenableBuilder<List<AdminUndoHistoryRow>>(
                      valueListenable: AdminDashboardState.undoHistory,
                      builder: (context, historyItems, _) {
                        return ValueListenableBuilder<AdminPagination>(
                          valueListenable:
                              AdminDashboardState.undoHistoryPagination,
                          builder: (context, historyPagination, _) {
                            return _UndoHistoryCard(
                              loading: historyLoading,
                              items: historyItems,
                              pagination: historyPagination,
                              selectedState: _undoHistoryStateFilter,
                              onStateChanged: (value) {
                                _setSectionState(() => _undoHistoryStateFilter = value);
                                unawaited(_loadUndoHistory(1));
                              },
                              onPageSelected: _loadUndoHistory,
                              onUndo: _undoFromHistory,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    if (!wide) {
                      return Column(
                        children: [
                          _ActivityCard(
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFF2563EB),
                            title: 'Recent Orders',
                            items: recentOrders
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.serviceName} • ${item.finderName} → ${item.providerName}',
                                    subtitle:
                                        '${_prettyStatus(item.status)} • ${_toMoney(item.total)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent orders for current filters.',
                          ),
                          const SizedBox(height: 12),
                          _ActivityCard(
                            icon: Icons.group_rounded,
                            color: const Color(0xFF14B8A6),
                            title: 'Recent Users',
                            items: recentUsers
                                .map(
                                  (item) => _ActivityItem(
                                    title: '${item.name} (${item.role})',
                                    subtitle: item.email.isEmpty
                                        ? 'No email'
                                        : item.email,
                                    trailing: _formatDateTime(
                                      item.updatedAt ?? item.createdAt,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent users for current filters.',
                          ),
                          const SizedBox(height: 12),
                          _ActivityCard(
                            icon: Icons.campaign_rounded,
                            color: const Color(0xFF7C3AED),
                            title: 'Recent Posts',
                            items: recentPosts
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.ownerName} • ${_prettyPostType(item.type)}',
                                    subtitle:
                                        '${item.service.isEmpty ? 'Service' : item.service} • ${_prettyStatus(item.status)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent posts for current filters.',
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ActivityCard(
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFF2563EB),
                            title: 'Recent Orders',
                            items: recentOrders
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.serviceName} • ${item.finderName} → ${item.providerName}',
                                    subtitle:
                                        '${_prettyStatus(item.status)} • ${_toMoney(item.total)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent orders for current filters.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActivityCard(
                            icon: Icons.group_rounded,
                            color: const Color(0xFF14B8A6),
                            title: 'Recent Users',
                            items: recentUsers
                                .map(
                                  (item) => _ActivityItem(
                                    title: '${item.name} (${item.role})',
                                    subtitle: item.email.isEmpty
                                        ? 'No email'
                                        : item.email,
                                    trailing: _formatDateTime(
                                      item.updatedAt ?? item.createdAt,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent users for current filters.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActivityCard(
                            icon: Icons.campaign_rounded,
                            color: const Color(0xFF7C3AED),
                            title: 'Recent Posts',
                            items: recentPosts
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.ownerName} • ${_prettyPostType(item.type)}',
                                    subtitle:
                                        '${item.service.isEmpty ? 'Service' : item.service} • ${_prettyStatus(item.status)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent posts for current filters.',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  row.generatedAt == null
                      ? 'Overview timestamp unavailable'
                      : 'Last synced: ${_formatDateTime(row.generatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
