part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildServicesSection() {
    return _AdminTableCard<AdminServiceRow>(
      title: 'Service Catalog',
      subtitle: 'Ensure service coverage and clean category mapping.',
      loadingListenable: AdminDashboardState.loadingServices,
      rowsListenable: AdminDashboardState.services,
      paginationListenable: AdminDashboardState.servicesPagination,
      onPageSelected: _loadServices,
      controls: [
        _DropdownFilter(
          label: 'Service state',
          value: _serviceStateFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All states'),
            _DropdownOption(value: 'active', label: 'Active'),
            _DropdownOption(value: 'inactive', label: 'Inactive'),
          ],
          onChanged: (value) {
            _setSectionState(() => _serviceStateFilter = value);
            unawaited(_loadServices(1));
          },
        ),
      ],
      columns: const ['Service', 'Category', 'State', 'Image', 'ID', 'Action'],
      emptyText: 'No services found for this page.',
      summaryBuilder: (items) {
        final active = items.where((item) => item.active).length;
        final inactive = items.length - active;
        return [
          _MetricChipData(label: 'Page services', value: '${items.length}'),
          _MetricChipData(
            label: 'Active',
            value: '$active',
            color: AppColors.success,
          ),
          _MetricChipData(
            label: 'Inactive',
            value: '$inactive',
            color: AppColors.warning,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final stateMatch =
                  _serviceStateFilter == 'all' ||
                  (_serviceStateFilter == 'active' && item.active) ||
                  (_serviceStateFilter == 'inactive' && !item.active);
              if (!stateMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.name} ${item.categoryName} ${item.id} ${item.categoryId}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(_cellText(item.name, width: 180)),
          DataCell(_cellText(item.categoryName, width: 170)),
          DataCell(
            _Pill(
              text: item.active ? 'Active' : 'Inactive',
              color: item.active ? AppColors.success : AppColors.warning,
            ),
          ),
          DataCell(
            _cellText(item.imageUrl.isEmpty ? '-' : 'Available', width: 100),
          ),
          DataCell(_cellText(item.id, width: 180)),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: item.active ? 'Deactivate' : 'Activate',
                  onTap: () => _runSafeAction(
                    dialogTitle:
                        '${item.active ? 'Deactivate' : 'Activate'} service ${item.name}?',
                    actionLabel: item.active ? 'Deactivate' : 'Activate',
                    run: (reason) => AdminDashboardState.updateServiceActive(
                      serviceId: item.id,
                      active: !item.active,
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
