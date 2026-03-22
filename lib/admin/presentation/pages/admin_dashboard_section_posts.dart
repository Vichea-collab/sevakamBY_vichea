part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildPostsSection() {
    return _AdminTableCard<AdminPostRow>(
      title: 'Post Streams',
      subtitle: 'Moderate finder requests and provider offers in one place.',
      loadingListenable: AdminDashboardState.loadingPosts,
      rowsListenable: AdminDashboardState.posts,
      paginationListenable: AdminDashboardState.postsPagination,
      onPageSelected: _loadPosts,
      controls: [
        _DropdownFilter(
          label: 'Post type',
          value: _postTypeFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All types'),
            _DropdownOption(value: 'provider_offer', label: 'Provider offer'),
            _DropdownOption(value: 'finder_request', label: 'Finder request'),
          ],
          onChanged: (value) {
            _setSectionState(() => _postTypeFilter = value);
            unawaited(_loadPosts(1));
          },
        ),
      ],
      columns: const [
        'Type',
        'Owner',
        'Category/Service',
        'Location',
        'Status',
        'Created',
        'Action',
      ],
      emptyText: 'No posts found for this page.',
      summaryBuilder: (items) {
        final offers = items
            .where((item) => item.type == 'provider_offer')
            .length;
        final requests = items
            .where((item) => item.type == 'finder_request')
            .length;
        final open = items
            .where((item) => item.status.toLowerCase() == 'open')
            .length;
        return [
          _MetricChipData(label: 'Page posts', value: '${items.length}'),
          _MetricChipData(
            label: 'Offers',
            value: '$offers',
            color: AppColors.primary,
          ),
          _MetricChipData(
            label: 'Requests',
            value: '$requests',
            color: const Color(0xFF14B8A6),
          ),
          _MetricChipData(
            label: 'Open',
            value: '$open',
            color: AppColors.success,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final typeMatch =
                  _postTypeFilter == 'all' || item.type == _postTypeFilter;
              if (!typeMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.type} ${item.ownerName} ${item.category} ${item.serviceSummary} ${item.serviceList.join(' ')} ${item.location} ${item.status} ${item.details}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(
            _Pill(
              text: _prettyPostType(item.type),
              color: _postTypeColor(item.type),
            ),
          ),
          DataCell(_cellText(item.ownerName, width: 155)),
          DataCell(_cellText(item.categoryServiceLabel, width: 210)),
          DataCell(
            _cellText(item.location.isEmpty ? '-' : item.location, width: 170),
          ),
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
                  label: 'View details',
                  onTap: () => unawaited(_showPostDetails(item)),
                ),
                _ActionMenuItem(
                  label: 'Open',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Open this post again?',
                    actionLabel: 'Open',
                    run: (reason) => AdminDashboardState.updatePostStatus(
                      sourceCollection: item.sourceCollection,
                      postId: item.id,
                      status: 'open',
                      reason: reason,
                    ),
                  ),
                ),
                _ActionMenuItem(
                  label: 'Close',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Close this post?',
                    actionLabel: 'Close',
                    run: (reason) => AdminDashboardState.updatePostStatus(
                      sourceCollection: item.sourceCollection,
                      postId: item.id,
                      status: 'closed',
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
