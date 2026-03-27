part of 'admin_dashboard_page.dart';

extension on _AdminDashboardPageState {
  Widget _buildTicketsSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminDashboardState.loadingTickets,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<List<AdminTicketRow>>(
          valueListenable: AdminDashboardState.tickets,
          builder: (context, rows, _) {
            return ValueListenableBuilder<AdminPagination>(
              valueListenable: AdminDashboardState.ticketsPagination,
              builder: (context, pageMeta, _) {
                final filteredRows = _filterTicketRows(rows);
                final initialLoading = isLoading && rows.isEmpty;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFD9E5F6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x100F172A),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTicketSectionHeader(
                        context,
                        isLoading: isLoading,
                        initialLoading: initialLoading,
                        visibleCount: filteredRows.length,
                        pageMeta: pageMeta,
                      ),
                      const SizedBox(height: 16),
                      _buildTicketFilterBar(),
                      const SizedBox(height: 16),
                      if (initialLoading)
                        const SizedBox(
                          height: 340,
                          child: Center(
                            child: _AdminLoadingPanel(
                              title: 'Loading tickets',
                              message:
                                  'Please wait while we fetch support requests.',
                            ),
                          ),
                        )
                      else if (filteredRows.isEmpty)
                        _buildTicketEmptyState(rows.isEmpty)
                      else
                        Column(
                          children: [
                            for (
                              var index = 0;
                              index < filteredRows.length;
                              index++
                            ) ...[
                              _buildTicketRequestCard(filteredRows[index]),
                              if (index < filteredRows.length - 1)
                                const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      if (!initialLoading) ...[
                        const SizedBox(height: 16),
                        _buildTicketFooter(pageMeta, filteredRows.length),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTicketSectionHeader(
    BuildContext context, {
    required bool isLoading,
    required bool initialLoading,
    required int visibleCount,
    required AdminPagination pageMeta,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFF2F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7F8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD9E5F8)),
                ),
                child: const Text(
                  'Support operations',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ticket workspace',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review support requests, open the right conversation quickly, and move each case forward with clear context.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          );

          final statusPanel = Container(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE6F7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'This page',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isLoading && !initialLoading)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$visibleCount visible tickets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Page ${pageMeta.page} of ${pageMeta.totalPages < 1 ? 1 : pageMeta.totalPages}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: headline),
                  ],
                ),
                const SizedBox(height: 16),
                statusPanel,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: headline),
              const SizedBox(width: 18),
              statusPanel,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE6F7)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE6F7)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Refine queue',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _DropdownFilter(
            label: 'Ticket status',
            value: _ticketStatusFilter,
            options: const [
              _DropdownOption(value: 'all', label: 'All statuses'),
              _DropdownOption(
                value: 'waiting_on_admin',
                label: 'Waiting on admin',
              ),
              _DropdownOption(
                value: 'waiting_on_user',
                label: 'Waiting on user',
              ),
              _DropdownOption(value: 'resolved', label: 'Resolved'),
              _DropdownOption(value: 'closed', label: 'Closed'),
              _DropdownOption(value: 'open', label: 'Open (legacy)'),
            ],
            onChanged: (value) {
              _setSectionState(() => _ticketStatusFilter = value);
              unawaited(_loadTickets(1));
            },
          ),
          _DropdownFilter(
            label: 'Category',
            value: _ticketCategoryFilter,
            options: [
              const _DropdownOption(value: 'all', label: 'All categories'),
              ...supportTicketCategories.map(
                (item) => _DropdownOption(value: item.id, label: item.label),
              ),
            ],
            onChanged: (value) {
              _setSectionState(() => _ticketCategoryFilter = value);
              unawaited(_loadTickets(1));
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE6F7)),
            ),
            child: const Text(
              'Search is linked to the dashboard search field above.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketEmptyState(bool noRows) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              noRows
                  ? 'No tickets available on this page.'
                  : 'No tickets matched the current filters.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another status, category, or search term to refine the queue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketFooter(AdminPagination pageMeta, int visibleCount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing $visibleCount tickets on page ${pageMeta.page} of ${pageMeta.totalPages < 1 ? 1 : pageMeta.totalPages}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _CompactPager(
          page: pageMeta.page,
          totalPages: pageMeta.totalPages,
          loading: AdminDashboardState.loadingTickets.value,
          onPageSelected: _loadTickets,
        ),
      ],
    );
  }

  List<AdminTicketRow> _filterTicketRows(List<AdminTicketRow> items) {
    final query = _searchQuery.trim().toLowerCase();
    return items
        .where((item) {
          final status = item.status.toLowerCase();
          final statusMatch =
              _ticketStatusFilter == 'all' || status == _ticketStatusFilter;
          if (!statusMatch) return false;
          final categoryMatch =
              _ticketCategoryFilter == 'all' ||
              item.category.toLowerCase() == _ticketCategoryFilter;
          if (!categoryMatch) return false;
          if (query.isEmpty) return true;
          final haystack =
              '${item.title} ${item.message} ${item.userUid} ${item.userName} ${item.userEmail} ${item.status} ${item.category} ${item.subcategory} ${item.priority}'
                  .toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  Widget _buildTicketRequestCard(AdminTicketRow item) {
    final status = item.status.toLowerCase();
    final hasNewReply = _ticketNeedsAdminReply(item);
    final roleColor = item.userRole.toLowerCase() == 'provider'
        ? const Color(0xFF7C3AED)
        : AppColors.primary;
    final latestAt = item.lastMessageAt ?? item.createdAt;
    final categoryLabel = supportTicketCategoryLabel(item.category);
    final subcategoryLabel = supportTicketSubcategoryLabel(
      categoryId: item.category,
      subcategoryId: item.subcategory,
    );
    final ticketTypeLabel = supportTicketRequestTypeLabel(
      supportTicketRequestTypeFromId(item.ticketType),
    );
    final displayTitle = item.title.trim().isEmpty
        ? subcategoryLabel
        : item.title;
    final previewText = item.message.trim().isEmpty
        ? '$ticketTypeLabel request created for $categoryLabel / $subcategoryLabel.'
        : item.message;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasNewReply
              ? const [Color(0xFFF9FCFF), Color(0xFFF4F9FF)]
              : const [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasNewReply
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFDCE6F7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 940;
              final narrowHeader = constraints.maxWidth < 760;
              final info = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          text: ticketTypeLabel,
                          color: item.ticketType.trim().toLowerCase() == 'support'
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF0F766E),
                        ),
                        _Pill(
                          text: categoryLabel,
                          color: const Color(0xFF2563EB),
                        ),
                        _Pill(
                          text: subcategoryLabel,
                          color: const Color(0xFF0EA5E9),
                        ),
                        _Pill(
                          text: _prettyTicketPriority(item.priority),
                          color: _ticketPriorityColor(item.priority),
                        ),
                        _Pill(
                          text: _prettyStatus(item.status),
                          color: _statusColor(item.status),
                        ),
                        if (hasNewReply)
                          const _Pill(
                            text: 'Awaiting admin reply',
                            color: Color(0xFF0EA5E9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayTitle,
                      maxLines: narrowHeader ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F4)),
                      ),
                      child: Text(
                        previewText,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final sidePanel = SizedBox(
                width: compact ? double.infinity : 320,
                child: _buildTicketMetaPanels(item, roleColor),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTicketLeadingIcon(hasNewReply),
                        const SizedBox(width: 14),
                        info,
                      ],
                    ),
                    const SizedBox(height: 16),
                    sidePanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTicketLeadingIcon(hasNewReply),
                  const SizedBox(width: 14),
                  info,
                  const SizedBox(width: 18),
                  sidePanel,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compactMeta = constraints.maxWidth < 760;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCE6F7)),
                ),
                child: compactMeta
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ticketDetailLine(
                            icon: Icons.schedule_rounded,
                            label: 'Latest activity',
                            value: _formatDateTime(latestAt),
                            compact: true,
                          ),
                          const SizedBox(height: 10),
                          _ticketDetailLine(
                            icon: Icons.person_outline_rounded,
                            label: 'Last sender',
                            value: _ticketLatestActorLabel(item),
                            compact: true,
                          ),
                          const SizedBox(height: 10),
                          _ticketDetailLine(
                            icon: Icons.confirmation_number_outlined,
                            label: 'Ticket ID',
                            value: item.id,
                            compact: true,
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _ticketDetailLine(
                            icon: Icons.schedule_rounded,
                            label: 'Latest activity',
                            value: _formatDateTime(latestAt),
                          ),
                          _ticketDetailLine(
                            icon: Icons.person_outline_rounded,
                            label: 'Last sender',
                            value: _ticketLatestActorLabel(item),
                          ),
                          _ticketDetailLine(
                            icon: Icons.confirmation_number_outlined,
                            label: 'Ticket ID',
                            value: item.id,
                          ),
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ticketActionButton(
                label: 'Open conversation',
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                prominent: true,
                onTap: () => _openTicketChat(item),
              ),
              if (status != 'resolved' && status != 'closed')
                _ticketActionButton(
                  label: 'Resolve',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Resolve ticket ${item.id}?',
                    actionLabel: 'Resolve',
                    run: (reason) => AdminDashboardState.updateTicketStatus(
                      userUid: item.userUid,
                      ticketId: item.id,
                      status: 'resolved',
                      reason: reason,
                    ),
                  ),
                ),
              if (status != 'closed')
                _ticketActionButton(
                  label: 'Close',
                  icon: Icons.lock_outline_rounded,
                  color: const Color(0xFF64748B),
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Close ticket ${item.id}?',
                    actionLabel: 'Close',
                    reasonRequired: true,
                    run: (reason) => AdminDashboardState.updateTicketStatus(
                      userUid: item.userUid,
                      ticketId: item.id,
                      status: 'closed',
                      reason: reason,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketMetaPanels(AdminTicketRow item, Color roleColor) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE6F7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Requester',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.userName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(text: _prettyRole(item.userRole), color: roleColor),
                  if (item.userEmail.isNotEmpty)
                    _Pill(
                      text: 'Verified contact',
                      color: const Color(0xFF64748B),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.userEmail.isEmpty ? item.userUid : item.userEmail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF4DFC1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Timeline',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ticketTimelineRow(
                label: 'Created',
                value: _formatDateTime(item.createdAt),
              ),
              const SizedBox(height: 8),
              _ticketTimelineRow(
                label: 'Latest reply',
                value: _formatDateTime(item.lastMessageAt ?? item.createdAt),
              ),
              const SizedBox(height: 8),
              _ticketTimelineRow(
                label: 'Ownership',
                value: _ticketNeedsAdminReply(item)
                    ? 'Admin action needed'
                    : 'Waiting on requester',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketLeadingIcon(bool hasNewReply) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: hasNewReply ? const Color(0xFFE0F2FE) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        hasNewReply
            ? Icons.mark_email_unread_rounded
            : Icons.support_agent_rounded,
        color: hasNewReply ? const Color(0xFF0284C7) : AppColors.primary,
      ),
    );
  }

  Widget _ticketActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Future<void> Function() onTap,
    bool prominent = false,
  }) {
    final background = prominent ? color : color.withValues(alpha: 0.10);
    final foreground = prominent ? Colors.white : color;
    return TextButton.icon(
      onPressed: () => unawaited(onTap()),
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _ticketDetailLine({
    required IconData icon,
    required String label,
    required String value,
    bool compact = false,
  }) {
    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _ticketTimelineRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  bool _ticketNeedsAdminReply(AdminTicketRow item) {
    final status = item.status.toLowerCase();
    return status != 'closed' &&
        item.lastMessageSenderRole.toLowerCase() == item.userRole.toLowerCase();
  }

  String _ticketLatestActorLabel(AdminTicketRow item) {
    final sender = item.lastMessageSenderRole.trim().toLowerCase();
    if (sender.isEmpty) return 'No replies yet';
    if (sender == 'admin') return 'Admin';
    if (sender == 'provider') return 'Provider';
    if (sender == 'finder') return 'Finder';
    return _prettyRole(sender);
  }

  String _prettyTicketPriority(String value) {
    switch (value.trim().toLowerCase()) {
      case 'high':
        return 'High priority';
      case 'low':
        return 'Low priority';
      default:
        return 'Normal priority';
    }
  }

  Color _ticketPriorityColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'low':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  List<String> _ticketQuickReplies(AdminTicketRow ticket) {
    switch (ticket.category.trim().toLowerCase()) {
      case 'payment_charge':
        return const [
          'Please send the payment screenshot and payment reference so we can verify the charge.',
          'We are checking the billing logs now and will update you shortly.',
          'Please confirm the charged amount and the expected amount.',
        ];
      case 'provider_issue':
      case 'finder_issue':
        return const [
          'Please share the related booking ID so we can review the case.',
          'Please attach screenshots or chat evidence if available.',
          'We have started reviewing this service dispute and will update you soon.',
        ];
      case 'booking_problem':
        return const [
          'Please tell us the exact booking status shown in the app.',
          'Please share the booking ID and a screenshot of the problem screen.',
          'We are reviewing the booking timeline now and will update you shortly.',
        ];
      case 'subscription_upgrade':
        return const [
          'Please share your plan name and payment screenshot so we can verify activation.',
          'We are checking your subscription payment and activation status now.',
          'Please confirm the account email used for this subscription.',
        ];
      case 'account_verification':
        return const [
          'Please confirm the account email and the current verification status shown in the app.',
          'Please attach a screenshot of the verification or login error.',
          'We are reviewing your account verification details now.',
        ];
      case 'app_bug':
        return const [
          'Please share the screen name and the steps to reproduce this issue.',
          'Please attach a screenshot or screen recording if available.',
          'We have logged this technical issue and are reviewing it now.',
        ];
      default:
        return const [
          'Thank you. Please share any screenshot or reference ID that can help us review this faster.',
          'We are reviewing your request and will update you shortly.',
        ];
    }
  }
}
