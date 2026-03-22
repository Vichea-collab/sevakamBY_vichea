part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildUsersSection() {
    return _AdminTableCard<AdminUserRow>(
      title: 'User Management',
      subtitle: 'Audit finder, provider, admin, and legacy account access.',
      loadingListenable: AdminDashboardState.loadingUsers,
      rowsListenable: AdminDashboardState.users,
      paginationListenable: AdminDashboardState.usersPagination,
      onPageSelected: _loadUsers,
      controls: [
        _DropdownFilter(
          label: 'Role',
          value: _userRoleFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All roles'),
            _DropdownOption(value: 'admin', label: 'Admin'),
            _DropdownOption(value: 'provider', label: 'Provider'),
            _DropdownOption(value: 'finder', label: 'Finder'),
            _DropdownOption(value: 'user', label: 'User'),
          ],
          onChanged: (value) {
            _setSectionState(() => _userRoleFilter = value);
            unawaited(_loadUsers(1));
          },
        ),
      ],
      columns: const ['Name', 'Email', 'Role', 'State', 'Updated', 'Action'],
      emptyText: 'No users found for this page.',
      summaryBuilder: (items) {
        final legacyUsers = items
            .where((item) => item.role.trim().toLowerCase() == 'user')
            .length;
        final admins = items
            .where((item) => item.role.toLowerCase().contains('admin'))
            .length;
        final providers = items
            .where((item) => item.role.toLowerCase().contains('provider'))
            .length;
        final finders = items
            .where((item) => item.role.toLowerCase().contains('finder'))
            .length;
        final suspended = items.where((item) => !item.active).length;
        return [
          _MetricChipData(label: 'Page users', value: '${items.length}'),
          _MetricChipData(
            label: 'Admin',
            value: '$admins',
            color: const Color(0xFF7C3AED),
          ),
          _MetricChipData(
            label: 'Provider',
            value: '$providers',
            color: AppColors.primary,
          ),
          _MetricChipData(
            label: 'Finder',
            value: '$finders',
            color: const Color(0xFF14B8A6),
          ),
          _MetricChipData(
            label: 'Legacy user',
            value: '$legacyUsers',
            color: const Color(0xFF64748B),
          ),
          _MetricChipData(
            label: 'Suspended',
            value: '$suspended',
            color: AppColors.warning,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final roleMatch = _userRoleFilter == 'all'
                  ? true
                  : item.role.toLowerCase().contains(_userRoleFilter);
              if (!roleMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.name} ${item.email} ${item.role} '
                          '${item.id} ${item.active ? 'active' : 'suspended'}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(_cellText(item.name, width: 170)),
          DataCell(
            _cellText(item.email.isEmpty ? '-' : item.email, width: 210),
          ),
          DataCell(
            _Pill(
              text: _userRoleLabel(item.role),
              color: _userRoleColor(item.role),
            ),
          ),
          DataCell(
            _Pill(
              text: item.active ? 'Active' : 'Suspended',
              color: item.active ? AppColors.success : AppColors.warning,
            ),
          ),
          DataCell(
            _cellText(_formatDateTime(item.updatedAt ?? item.createdAt)),
          ),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: item.active ? 'Suspend' : 'Activate',
                  onTap: () => _runSafeAction(
                    dialogTitle:
                        '${item.active ? 'Suspend' : 'Activate'} user ${item.name}?',
                    actionLabel: item.active ? 'Suspend' : 'Activate',
                    run: (reason) => AdminDashboardState.updateUserStatus(
                      userId: item.id,
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

  String _userRoleLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'user') return 'Legacy User';
    return _prettyRole(value);
  }

  Color _userRoleColor(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('admin')) return const Color(0xFF7C3AED);
    if (normalized.contains('provider')) return AppColors.primary;
    if (normalized.contains('finder')) return const Color(0xFF14B8A6);
    return const Color(0xFF64748B);
  }
}
