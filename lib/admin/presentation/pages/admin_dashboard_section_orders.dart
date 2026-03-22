part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildOrdersSection() {
    return _AdminTableCard<AdminOrderRow>(
      title: 'Order Operations',
      subtitle: 'Track booking lifecycle and order status.',
      loadingListenable: AdminDashboardState.loadingOrders,
      rowsListenable: AdminDashboardState.orders,
      paginationListenable: AdminDashboardState.ordersPagination,
      onPageSelected: _loadOrders,
      controls: [
        _DropdownFilter(
          label: 'Status',
          value: _orderStatusFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All statuses'),
            _DropdownOption(value: 'booked', label: 'Booked'),
            _DropdownOption(value: 'on_the_way', label: 'On the way'),
            _DropdownOption(value: 'started', label: 'Started'),
            _DropdownOption(value: 'completed', label: 'Completed'),
            _DropdownOption(value: 'cancelled', label: 'Cancelled'),
            _DropdownOption(value: 'declined', label: 'Declined'),
          ],
          onChanged: (value) {
            _setSectionState(() => _orderStatusFilter = value);
            unawaited(_loadOrders(1));
          },
        ),
      ],
      columns: const [
        'Service',
        'Finder',
        'Provider',
        'Status',
        'Created',
        'Action',
      ],
      emptyText: 'No orders found for this page.',
      summaryBuilder: (items) {
        final completed = items
            .where((item) => item.status == 'completed')
            .length;
        final pending = items.where((item) => item.status == 'booked').length;
        return [
          _MetricChipData(label: 'Page orders', value: '${items.length}'),
          _MetricChipData(
            label: 'Completed',
            value: '$completed',
            color: AppColors.success,
          ),
          _MetricChipData(
            label: 'Booked',
            value: '$pending',
            color: AppColors.warning,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final statusMatch =
                  _orderStatusFilter == 'all' ||
                  item.status.toLowerCase() == _orderStatusFilter;
              if (!statusMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.serviceName} ${item.finderName} ${item.providerName} ${item.status}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(_cellText(item.serviceName, width: 170)),
          DataCell(_cellText(item.finderName, width: 150)),
          DataCell(_cellText(item.providerName, width: 150)),
          DataCell(
            _Pill(
              text: _prettyStatus(item.status),
              color: _statusColor(item.status),
            ),
          ),
          DataCell(_cellText(_formatDateTime(item.createdAt))),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: 'Mark completed',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Mark order ${item.id} complete?',
                    actionLabel: 'Complete',
                    run: (reason) => AdminDashboardState.updateOrderStatus(
                      orderId: item.id,
                      status: 'completed',
                      reason: reason,
                    ),
                  ),
                ),
                _ActionMenuItem(
                  label: 'Mark cancelled',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Mark order ${item.id} as cancelled?',
                    actionLabel: 'Cancel',
                    run: (reason) => AdminDashboardState.updateOrderStatus(
                      orderId: item.id,
                      status: 'cancelled',
                      reason: reason,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }
}
