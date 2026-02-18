part of 'admin_dashboard_page.dart';

const Color _adminFieldBorderColor = Color(0xFFD3DDEF);
const Color _adminFieldFillColor = Color(0xFFF8FAFF);

InputDecoration _adminFieldDecoration({
  String? labelText,
  String? hintText,
  bool dense = false,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: _adminFieldFillColor,
    isDense: dense,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _adminFieldBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
    ),
  );
}

class _DashboardSidebar extends StatelessWidget {
  final String email;
  final _AdminSection section;
  final ValueChanged<_AdminSection> onSectionChanged;
  final Future<void> Function() onLogout;

  const _DashboardSidebar({
    required this.email,
    required this.section,
    required this.onSectionChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD7E2F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [Color(0xFF0F5CD7), Color(0xFF5C8FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sevakam Admin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _AdminSection.values.length,
                itemBuilder: (context, index) {
                  final item = _AdminSection.values[index];
                  final selected = item == section;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSectionChanged(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 24,
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE3EAF9)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFD5DEEF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardToolbar extends StatelessWidget {
  final _AdminSection section;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSubmitSearch;
  final Future<void> Function() onClearSearch;

  const _DashboardToolbar({
    required this.section,
    required this.searchController,
    required this.onRefresh,
    required this.onSubmitSearch,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8E3F6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        section.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => unawaited(onSubmitSearch()),
              decoration: InputDecoration(
                hintText: 'Search current section...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () => unawaited(onClearSearch()),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    IconButton(
                      onPressed: () => unawaited(onSubmitSearch()),
                      icon: const Icon(Icons.search_rounded),
                    ),
                  ],
                ),
                filled: true,
                fillColor: _adminFieldFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _adminFieldBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _adminFieldBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTableCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final ValueListenable<bool> loadingListenable;
  final ValueListenable<List<T>> rowsListenable;
  final ValueListenable<AdminPagination> paginationListenable;
  final Future<void> Function(int page) onPageSelected;
  final List<Widget> controls;
  final List<String> columns;
  final String emptyText;
  final List<_MetricChipData> Function(List<T> items) summaryBuilder;
  final List<T> Function(List<T> items) filterRows;
  final List<DataCell> Function(T row) rowCells;

  const _AdminTableCard({
    required this.title,
    required this.subtitle,
    required this.loadingListenable,
    required this.rowsListenable,
    required this.paginationListenable,
    required this.onPageSelected,
    required this.controls,
    required this.columns,
    required this.emptyText,
    required this.summaryBuilder,
    required this.filterRows,
    required this.rowCells,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loadingListenable,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<List<T>>(
          valueListenable: rowsListenable,
          builder: (context, rows, _) {
            return ValueListenableBuilder<AdminPagination>(
              valueListenable: paginationListenable,
              builder: (context, pageMeta, _) {
                final filteredRows = filterRows(rows);
                final summaries = summaryBuilder(rows);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8E3F6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (isLoading)
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (controls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 10, runSpacing: 8, children: controls),
                      ],
                      if (summaries.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: summaries
                              .map(
                                (item) => _Pill(
                                  text: '${item.label}: ${item.value}',
                                  color: item.color,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (filteredRows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            rows.isEmpty
                                ? emptyText
                                : 'No rows matched your search/filter in this page.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              const Color(0xFFF4F7FF),
                            ),
                            columns: columns
                                .map(
                                  (name) => DataColumn(
                                    label: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            rows: filteredRows
                                .map((row) => DataRow(cells: rowCells(row)))
                                .toList(growable: false),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Page ${pageMeta.page} • ${filteredRows.length}/${rows.length} visible • ${pageMeta.totalItems} total items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CompactPager(
                        page: pageMeta.page,
                        totalPages: pageMeta.totalPages,
                        loading: isLoading,
                        onPageSelected: onPageSelected,
                      ),
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
}

class _BroadcastComposerCard extends StatelessWidget {
  final String type;
  final String discountType;
  final bool finderSelected;
  final bool providerSelected;
  final bool active;
  final bool saving;
  final TextEditingController titleController;
  final TextEditingController messageController;
  final TextEditingController promoCodeController;
  final TextEditingController discountValueController;
  final TextEditingController minSubtotalController;
  final TextEditingController maxDiscountController;
  final TextEditingController usageLimitController;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onDiscountTypeChanged;
  final VoidCallback onFinderToggle;
  final VoidCallback onProviderToggle;
  final ValueChanged<bool> onActiveChanged;
  final Future<void> Function() onSubmit;

  const _BroadcastComposerCard({
    required this.type,
    required this.discountType,
    required this.finderSelected,
    required this.providerSelected,
    required this.active,
    required this.saving,
    required this.titleController,
    required this.messageController,
    required this.promoCodeController,
    required this.discountValueController,
    required this.minSubtotalController,
    required this.maxDiscountController,
    required this.usageLimitController,
    required this.onTypeChanged,
    required this.onDiscountTypeChanged,
    required this.onFinderToggle,
    required this.onProviderToggle,
    required this.onActiveChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isPromo = type == 'promotion';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E3F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast Composer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Publish system messages and promo campaigns to finder/provider notifications.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (saving)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (saving)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _composerControls(context, isPromo),
                    const SizedBox(height: 10),
                    _composerInputs(context, isPromo),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: _composerControls(context, isPromo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _composerInputs(context, isPromo)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: saving ? null : () => unawaited(onSubmit()),
              icon: const Icon(Icons.send_rounded),
              label: Text(saving ? 'Publishing...' : 'Publish broadcast'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composerControls(BuildContext context, bool isPromo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: type,
          isExpanded: true,
          dropdownColor: _adminFieldFillColor,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: _adminFieldDecoration(
            labelText: 'Broadcast type',
            dense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('System')),
            DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
          ],
          onChanged: (next) {
            if (next == null) return;
            onTypeChanged(next);
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Audience',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: finderSelected,
              label: const Text('Finder'),
              onSelected: (_) => onFinderToggle(),
              selectedColor: AppColors.primary.withValues(alpha: 0.16),
              side: BorderSide(
                color: finderSelected
                    ? AppColors.primary
                    : const Color(0xFFD3DDEF),
              ),
            ),
            FilterChip(
              selected: providerSelected,
              label: const Text('Provider'),
              onSelected: (_) => onProviderToggle(),
              selectedColor: AppColors.primary.withValues(alpha: 0.16),
              side: BorderSide(
                color: providerSelected
                    ? AppColors.primary
                    : const Color(0xFFD3DDEF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: active,
          title: const Text('Active now'),
          subtitle: const Text('Turn off to save as inactive'),
          onChanged: onActiveChanged,
        ),
        if (isPromo) ...[
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: discountType,
            isExpanded: true,
            dropdownColor: _adminFieldFillColor,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: _adminFieldDecoration(
              labelText: 'Discount type',
              dense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'percent', child: Text('Percent (%)')),
              DropdownMenuItem(value: 'fixed', child: Text('Fixed (USD)')),
            ],
            onChanged: (next) {
              if (next == null) return;
              onDiscountTypeChanged(next);
            },
          ),
        ],
      ],
    );
  }

  Widget _composerInputs(BuildContext context, bool isPromo) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: _adminFieldDecoration(
            labelText: 'Title',
            hintText: 'Short headline for notification',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: messageController,
          minLines: 3,
          maxLines: 4,
          decoration: _adminFieldDecoration(
            labelText: 'Message',
            hintText: 'Write announcement or promo details',
          ),
        ),
        if (isPromo) ...[
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              if (!wide) {
                return Column(
                  children: [
                    TextField(
                      controller: promoCodeController,
                      decoration: _adminFieldDecoration(
                        labelText: 'Promo code',
                        hintText: 'PROMO20',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: discountValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _adminFieldDecoration(
                              labelText: 'Discount',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: minSubtotalController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _adminFieldDecoration(
                              labelText: 'Min subtotal',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: maxDiscountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _adminFieldDecoration(
                              labelText: 'Max discount',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: usageLimitController,
                            keyboardType: TextInputType.number,
                            decoration: _adminFieldDecoration(
                              labelText: 'Usage limit',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: promoCodeController,
                          decoration: _adminFieldDecoration(
                            labelText: 'Promo code',
                            hintText: 'PROMO20',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: discountValueController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _adminFieldDecoration(
                            labelText: 'Discount',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: minSubtotalController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _adminFieldDecoration(
                            labelText: 'Min subtotal',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: maxDiscountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _adminFieldDecoration(
                            labelText: 'Max discount',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: usageLimitController,
                          keyboardType: TextInputType.number,
                          decoration: _adminFieldDecoration(
                            labelText: 'Usage limit (0 = unlimited)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _OverviewKpiGrid extends StatelessWidget {
  final Map<String, num> kpis;

  const _OverviewKpiGrid({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiData(
        label: 'Users',
        value: '${_intValue(kpis['users'])}',
        icon: Icons.group_rounded,
      ),
      _KpiData(
        label: 'Finders',
        value: '${_intValue(kpis['finders'])}',
        icon: Icons.person_search_rounded,
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
        label: 'Completed Revenue',
        value: _toMoney(_numValue(kpis['completedRevenue'])),
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
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(card.icon, color: AppColors.primary, size: 44),
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
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 10),
          if (items.isEmpty)
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

class _CompactPager extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool loading;
  final Future<void> Function(int page) onPageSelected;

  const _CompactPager({
    required this.page,
    required this.totalPages,
    required this.loading,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final pages = _buildPages(page, totalPages);
    final canPrev = page > 1 && !loading;
    final canNext = page < totalPages && !loading;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _pagerButton(
            icon: Icons.chevron_left_rounded,
            enabled: canPrev,
            onTap: () => onPageSelected(page - 1),
          ),
          const SizedBox(width: 8),
          for (final token in pages) ...[
            if (token is int)
              _pagerButton(
                label: '$token',
                selected: token == page,
                enabled: !loading,
                onTap: () => onPageSelected(token),
              )
            else
              _pagerButton(label: '...', enabled: false, onTap: null),
            const SizedBox(width: 8),
          ],
          _pagerButton(
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: () => onPageSelected(page + 1),
          ),
        ],
      ),
    );
  }

  Widget _pagerButton({
    String label = '',
    IconData? icon,
    bool selected = false,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final background = selected ? AppColors.primary : Colors.white;
    final border = selected ? AppColors.primary : const Color(0xFFD1DBEE);
    final foreground = selected
        ? Colors.white
        : enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        width: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x332C5EFF),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: icon != null
            ? Icon(icon, color: foreground)
            : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
      ),
    );
  }

  List<Object> _buildPages(int currentPage, int totalPages) {
    if (totalPages <= 7) {
      return List<Object>.generate(totalPages, (index) => index + 1);
    }

    final raw = <int>{1, totalPages, currentPage};
    if (currentPage - 1 > 1) raw.add(currentPage - 1);
    if (currentPage + 1 < totalPages) raw.add(currentPage + 1);
    if (currentPage <= 3) {
      raw.add(2);
      raw.add(3);
    }
    if (currentPage >= totalPages - 2) {
      raw.add(totalPages - 1);
      raw.add(totalPages - 2);
    }

    final sorted =
        raw.where((value) => value >= 1 && value <= totalPages).toList()
          ..sort();

    final tokens = <Object>[];
    for (var index = 0; index < sorted.length; index++) {
      final current = sorted[index];
      tokens.add(current);
      if (index == sorted.length - 1) continue;
      final next = sorted[index + 1];
      if (next - current > 1) {
        tokens.add('ellipsis');
      }
    }
    return tokens;
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<_DropdownOption> options;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: _adminFieldFillColor,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: _adminFieldDecoration(labelText: label, dense: true),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              ),
            )
            .toList(growable: false),
        onChanged: (next) {
          if (next == null) return;
          onChanged(next);
        },
      ),
    );
  }
}

class _DropdownOption {
  final String value;
  final String label;

  const _DropdownOption({required this.value, required this.label});
}

class _ActionMenuItem {
  final String label;
  final FutureOr<void> Function() onTap;

  const _ActionMenuItem({required this.label, required this.onTap});
}

class _MetricChipData {
  final String label;
  final String value;
  final Color color;

  const _MetricChipData({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
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

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BootstrappingView extends StatelessWidget {
  const _BootstrappingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E3F7)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.3),
            ),
            SizedBox(width: 12),
            Text('Loading admin workspace...'),
          ],
        ),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  final String email;
  final Future<void> Function() onLogout;

  const _MobileTopBar({required this.email, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F5CD7), Color(0xFF5C8FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332563EB),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sevakam Admin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  final double diameter;
  final Color color;

  const _GlowBubble({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

Widget _cellText(String value, {double width = 130}) {
  return SizedBox(
    width: width,
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppColors.textPrimary),
    ),
  );
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

String _toMoney(num value) => '\$${value.toStringAsFixed(2)}';

int _intValue(num? value) => value?.toInt() ?? 0;

double _numValue(num? value) => value?.toDouble() ?? 0;

String _prettyStatus(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'Unknown';
  return normalized
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _prettyPostType(String value) {
  return switch (value.trim().toLowerCase()) {
    'provider_offer' => 'Provider Offer',
    'finder_request' => 'Finder Request',
    _ => 'Post',
  };
}

Color _statusColor(String status) {
  return switch (status.trim().toLowerCase()) {
    'completed' => AppColors.success,
    'booked' => AppColors.warning,
    'on_the_way' => AppColors.primary,
    'started' => const Color(0xFF0284C7),
    'cancelled' => AppColors.danger,
    'declined' => const Color(0xFFE11D48),
    'resolved' => AppColors.success,
    'closed' => const Color(0xFF64748B),
    'active' => AppColors.success,
    'scheduled' => AppColors.warning,
    'expired' => AppColors.danger,
    'inactive' => const Color(0xFF64748B),
    _ => AppColors.textSecondary,
  };
}

Color _postTypeColor(String type) {
  return switch (type.trim().toLowerCase()) {
    'provider_offer' => AppColors.primary,
    'finder_request' => const Color(0xFF14B8A6),
    _ => AppColors.textSecondary,
  };
}

Color _undoStateColor(String state) {
  return switch (state.trim().toLowerCase()) {
    'available' => AppColors.success,
    'used' => const Color(0xFF64748B),
    'expired' => AppColors.warning,
    _ => AppColors.textSecondary,
  };
}

String _prettyUndoActionType(String actionType) {
  final value = actionType.trim().toLowerCase();
  switch (value) {
    case 'user_status':
      return 'User status';
    case 'order_status':
      return 'Order status';
    case 'post_status':
      return 'Post status';
    case 'ticket_status':
      return 'Ticket status';
    case 'service_active':
      return 'Service state';
    default:
      return _prettyStatus(value);
  }
}
