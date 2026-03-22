part of '../pages/admin_dashboard_page.dart';

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
                final initialLoading = isLoading && rows.isEmpty;

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
                          if (isLoading && !initialLoading)
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (isLoading && !initialLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (controls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 10, runSpacing: 8, children: controls),
                      ],
                      if (summaries.isNotEmpty && !initialLoading) ...[
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
                      if (initialLoading)
                        const SizedBox(
                          height: 280,
                          child: Center(
                            child: _AdminLoadingPanel(
                              title: 'Loading records',
                              message:
                                  'Please wait while we fetch this section.',
                            ),
                          ),
                        )
                      else if (filteredRows.isEmpty)
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
                        ScrollConfiguration(
                          behavior: const _AdminScrollBehavior(),
                          child: SingleChildScrollView(
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
                        ),
                      if (!initialLoading) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Page ${pageMeta.page} • ${filteredRows.length}/${rows.length} visible • ${pageMeta.totalItems} total items',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        _CompactPager(
                          page: pageMeta.page,
                          totalPages: pageMeta.totalPages,
                          loading: isLoading,
                          onPageSelected: onPageSelected,
                        ),
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
