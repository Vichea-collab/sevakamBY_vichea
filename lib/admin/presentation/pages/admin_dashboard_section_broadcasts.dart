part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Future<void> _submitBroadcastComposer() async {
    final title = _broadcastTitleController.text.trim();
    final message = _broadcastMessageController.text.trim();
    if (title.length < 3 || message.length < 3) {
      _showError(
        const AdminApiException(
          'Broadcast title and message must be at least 3 characters.',
        ),
      );
      return;
    }

    final targetRoles = <String>[
      if (_broadcastComposerFinder) 'finder',
      if (_broadcastComposerProvider) 'provider',
    ];
    if (targetRoles.isEmpty) {
      _showError(const AdminApiException('Select at least one audience role.'));
      return;
    }

    _setSectionState(() => _broadcastComposerSaving = true);
    try {
      await _runAuthed(
        () => AdminDashboardState.createBroadcast(
          type: _broadcastComposerType,
          title: title,
          message: message,
          targetRoles: targetRoles,
          active: _broadcastComposerActive,
        ),
      );

      _broadcastTitleController.clear();
      _broadcastMessageController.clear();
      _broadcastComposerType = 'system';
      _broadcastComposerActive = true;
      _broadcastComposerFinder = true;
      _broadcastComposerProvider = true;

      await _loadBroadcasts(1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast published successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        _setSectionState(() => _broadcastComposerSaving = false);
      }
    }
  }

  Future<void> _toggleBroadcastActive(AdminBroadcastRow row) async {
    final nextActive = !row.active;
    try {
      await _runAuthed(
        () => AdminDashboardState.updateBroadcastActive(
          broadcastId: row.id,
          active: nextActive,
        ),
      );
      await _loadBroadcasts(1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextActive
                ? 'Broadcast activated successfully.'
                : 'Broadcast deactivated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Widget _buildBroadcastsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BroadcastComposerCard(
          type: _broadcastComposerType,
          finderSelected: _broadcastComposerFinder,
          providerSelected: _broadcastComposerProvider,
          active: _broadcastComposerActive,
          saving: _broadcastComposerSaving,
          titleController: _broadcastTitleController,
          messageController: _broadcastMessageController,
          onTypeChanged: (value) =>
              _setSectionState(() => _broadcastComposerType = value),
          onFinderToggle: () => _setSectionState(
            () => _broadcastComposerFinder = !_broadcastComposerFinder,
          ),
          onProviderToggle: () => _setSectionState(
            () => _broadcastComposerProvider = !_broadcastComposerProvider,
          ),
          onActiveChanged: (value) =>
              _setSectionState(() => _broadcastComposerActive = value),
          onSubmit: _submitBroadcastComposer,
        ),
        const SizedBox(height: 12),
        _AdminTableCard<AdminBroadcastRow>(
          title: 'Broadcast Feed',
          subtitle: 'Monitor system notices and promotion lifecycle.',
          loadingListenable: AdminDashboardState.loadingBroadcasts,
          rowsListenable: AdminDashboardState.broadcasts,
          paginationListenable: AdminDashboardState.broadcastsPagination,
          onPageSelected: _loadBroadcasts,
          controls: [
            _DropdownFilter(
              label: 'Type',
              value: _broadcastTypeFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All types'),
                _DropdownOption(value: 'system', label: 'System'),
                _DropdownOption(value: 'promotion', label: 'Promotion'),
              ],
              onChanged: (value) {
                _setSectionState(() => _broadcastTypeFilter = value);
                unawaited(_loadBroadcasts(1));
              },
            ),
            _DropdownFilter(
              label: 'Lifecycle',
              value: _broadcastStatusFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All states'),
                _DropdownOption(value: 'active', label: 'Active'),
                _DropdownOption(value: 'scheduled', label: 'Scheduled'),
                _DropdownOption(value: 'expired', label: 'Expired'),
                _DropdownOption(value: 'inactive', label: 'Inactive'),
              ],
              onChanged: (value) {
                _setSectionState(() => _broadcastStatusFilter = value);
                unawaited(_loadBroadcasts(1));
              },
            ),
            _DropdownFilter(
              label: 'Audience',
              value: _broadcastRoleFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All audience'),
                _DropdownOption(value: 'finder', label: 'Finder'),
                _DropdownOption(value: 'provider', label: 'Provider'),
              ],
              onChanged: (value) {
                _setSectionState(() => _broadcastRoleFilter = value);
                unawaited(_loadBroadcasts(1));
              },
            ),
          ],
          columns: const [
            'Type',
            'Title',
            'Audience',
            'Lifecycle',
            'Created',
            'Action',
          ],
          emptyText: 'No broadcasts found for this page.',
          summaryBuilder: (items) {
            final active = items
                .where((item) => item.lifecycle.toLowerCase() == 'active')
                .length;
            final promos = items
                .where((item) => item.type.toLowerCase() == 'promotion')
                .length;
            final scheduled = items
                .where((item) => item.lifecycle.toLowerCase() == 'scheduled')
                .length;
            return [
              _MetricChipData(
                label: 'Page broadcasts',
                value: '${items.length}',
              ),
              _MetricChipData(
                label: 'Active',
                value: '$active',
                color: AppColors.success,
              ),
              _MetricChipData(
                label: 'Promotions',
                value: '$promos',
                color: const Color(0xFF0EA5E9),
              ),
              _MetricChipData(
                label: 'Scheduled',
                value: '$scheduled',
                color: AppColors.warning,
              ),
            ];
          },
          filterRows: (items) {
            final query = _searchQuery.trim().toLowerCase();
            return items
                .where((item) {
                  final typeMatch =
                      _broadcastTypeFilter == 'all' ||
                      item.type.toLowerCase() == _broadcastTypeFilter;
                  if (!typeMatch) return false;
                  final lifecycleMatch =
                      _broadcastStatusFilter == 'all' ||
                      item.lifecycle.toLowerCase() == _broadcastStatusFilter;
                  if (!lifecycleMatch) return false;
                  final roleMatch =
                      _broadcastRoleFilter == 'all' ||
                      item.targetRoles.any(
                        (role) =>
                            role.toLowerCase().trim() == _broadcastRoleFilter,
                      );
                  if (!roleMatch) return false;
                  if (query.isEmpty) return true;
                  final haystack =
                      '${item.type} ${item.title} ${item.message} ${item.lifecycle} ${item.targetRoles.join(' ')}'
                          .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);
          },
          rowCells: (item) {
            final type = item.type.toLowerCase();
            final typeColor = type == 'promotion'
                ? const Color(0xFF0EA5E9)
                : AppColors.primary;
            return [
              DataCell(_Pill(text: _prettyStatus(item.type), color: typeColor)),
              DataCell(_cellText(item.title, width: 210)),
              DataCell(_cellText(item.targetRoles.join(', '), width: 140)),
              DataCell(
                _Pill(
                  text: _prettyStatus(item.lifecycle),
                  color: _statusColor(item.lifecycle),
                ),
              ),
              DataCell(_cellText(_formatDateTime(item.createdAt), width: 150)),
              DataCell(
                _actionMenu(
                  actions: [
                    _ActionMenuItem(
                      label: item.active ? 'Deactivate' : 'Activate',
                      onTap: () => _toggleBroadcastActive(item),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }
}
