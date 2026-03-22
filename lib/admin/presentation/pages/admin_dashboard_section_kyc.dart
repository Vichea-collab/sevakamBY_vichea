part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildKycSection() {
    return _AdminTableCard<AdminUserRow>(
      title: 'Provider Verification (KYC)',
      subtitle:
          'Review uploaded ID documents and approve provider verification.',
      loadingListenable: AdminDashboardState.loadingUsers,
      rowsListenable: AdminDashboardState.users,
      paginationListenable: AdminDashboardState.usersPagination,
      onPageSelected: _loadUsers,
      controls: [
        _DropdownFilter(
          label: 'KYC',
          value: _userKycFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All KYC'),
            _DropdownOption(value: 'pending', label: 'Pending'),
            _DropdownOption(value: 'approved', label: 'Approved'),
            _DropdownOption(value: 'rejected', label: 'Rejected'),
            _DropdownOption(value: 'unverified', label: 'Unverified'),
          ],
          onChanged: (value) {
            _setSectionState(() => _userKycFilter = value);
            unawaited(_loadUsers(1));
          },
        ),
        _DropdownFilter(
          label: 'Plan',
          value: _userPlanFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All plans'),
            _DropdownOption(value: 'basic', label: 'Basic'),
            _DropdownOption(value: 'professional', label: 'Professional'),
            _DropdownOption(value: 'elite', label: 'Elite'),
          ],
          onChanged: (value) {
            _setSectionState(() => _userPlanFilter = value);
            unawaited(_loadUsers(1));
          },
        ),
      ],
      columns: const [
        'Provider',
        'Email',
        'KYC',
        'Submitted',
        'Documents',
        'Plan',
        'State',
        'Action',
      ],
      emptyText: 'No provider KYC records found for this page.',
      summaryBuilder: (items) {
        final pending = items
            .where((item) => item.providerKycStatus == 'pending')
            .length;
        final approved = items
            .where((item) => item.providerKycStatus == 'approved')
            .length;
        final rejected = items
            .where((item) => item.providerKycStatus == 'rejected')
            .length;
        final withDocs = items
            .where(
              (item) =>
                  item.providerKycIdFrontUrl.trim().isNotEmpty ||
                  item.providerKycIdBackUrl.trim().isNotEmpty,
            )
            .length;
        return [
          _MetricChipData(label: 'Page providers', value: '${items.length}'),
          _MetricChipData(
            label: 'Pending',
            value: '$pending',
            color: AppColors.warning,
          ),
          _MetricChipData(
            label: 'Approved',
            value: '$approved',
            color: AppColors.success,
          ),
          _MetricChipData(
            label: 'Rejected',
            value: '$rejected',
            color: AppColors.danger,
          ),
          _MetricChipData(
            label: 'With docs',
            value: '$withDocs',
            color: AppColors.primary,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              if (!_isProviderRole(item.role)) return false;
              if (_userKycFilter != 'all' &&
                  item.providerKycStatus != _userKycFilter) {
                return false;
              }
              if (_userPlanFilter != 'all' &&
                  item.providerSubscriptionTier != _userPlanFilter) {
                return false;
              }
              if (query.isEmpty) return true;
              final haystack =
                  '${item.name} ${item.email} ${item.id} ${item.providerKycStatus} '
                          '${item.providerSubscriptionTier} ${item.providerSubscriptionStatus}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        final hasDocs =
            item.providerKycIdFrontUrl.trim().isNotEmpty ||
            item.providerKycIdBackUrl.trim().isNotEmpty;
        return [
          DataCell(_cellText(item.name, width: 180)),
          DataCell(
            _cellText(item.email.isEmpty ? '-' : item.email, width: 220),
          ),
          DataCell(
            _Pill(
              text: _prettyKycStatus(item.providerKycStatus),
              color: _kycStatusColor(item.providerKycStatus),
            ),
          ),
          DataCell(
            _cellText(
              item.providerKycSubmittedAt == null
                  ? '-'
                  : _formatDateTime(item.providerKycSubmittedAt),
            ),
          ),
          DataCell(
            hasDocs
                ? TextButton(
                    onPressed: () => _showKycDocuments(item),
                    child: const Text('View docs'),
                  )
                : _cellText('-'),
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
            _Pill(
              text: item.active ? 'Active' : 'Suspended',
              color: item.active ? AppColors.success : AppColors.warning,
            ),
          ),
          DataCell(_actionMenu(actions: _providerKycActionItems(item))),
        ];
      },
    );
  }

  List<_ActionMenuItem> _providerKycActionItems(AdminUserRow item) {
    return [
      _ActionMenuItem(
        label: 'View KYC documents',
        onTap: () => _showKycDocuments(item),
      ),
      _ActionMenuItem(
        label: 'Set KYC pending',
        onTap: () => _runSafeAction(
          dialogTitle: 'Mark ${item.name} as pending KYC review?',
          actionLabel: 'Set pending',
          run: (reason) => AdminDashboardState.updateProviderKycStatus(
            providerId: item.id,
            status: 'pending',
            reason: reason,
          ),
        ),
      ),
      _ActionMenuItem(
        label: 'Approve KYC',
        onTap: () => _runSafeAction(
          dialogTitle: 'Approve KYC for ${item.name}?',
          actionLabel: 'Approve',
          run: (reason) => AdminDashboardState.updateProviderKycStatus(
            providerId: item.id,
            status: 'approved',
            reason: reason,
          ),
        ),
      ),
      _ActionMenuItem(
        label: 'Reject KYC',
        onTap: () => _runSafeAction(
          dialogTitle: 'Reject KYC for ${item.name}?',
          actionLabel: 'Reject',
          run: (reason) => AdminDashboardState.updateProviderKycStatus(
            providerId: item.id,
            status: 'rejected',
            reason: reason,
          ),
        ),
      ),
      _ActionMenuItem(
        label: 'Reset KYC',
        onTap: () => _runSafeAction(
          dialogTitle: 'Reset KYC for ${item.name} to unverified?',
          actionLabel: 'Reset',
          run: (reason) => AdminDashboardState.updateProviderKycStatus(
            providerId: item.id,
            status: 'unverified',
            reason: reason,
          ),
        ),
      ),
    ];
  }

  bool _isProviderRole(String role) {
    return role.toLowerCase().contains('provider');
  }

  String _prettyKycStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unverified';
    }
  }

  Color _kycStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.danger;
      default:
        return const Color(0xFF64748B);
    }
  }
}
