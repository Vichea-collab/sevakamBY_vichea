import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool loading;
  final ValueChanged<int> onPageSelected;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final pages = _buildPages();
    final canPrev = currentPage > 1 && !loading;
    final canNext = currentPage < totalPages && !loading;

    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: loading ? 0.8 : 1,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE3E8F2)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _arrowButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: canPrev,
                  onTap: () => onPageSelected(currentPage - 1),
                ),
                const SizedBox(width: 8),
                for (final token in pages) ...[
                  if (token is int)
                    _pageButton(
                      label: '$token',
                      active: token == currentPage,
                      enabled: !loading,
                      onTap: () => onPageSelected(token),
                    )
                  else
                    _pageButton(
                      label: '...',
                      active: false,
                      enabled: false,
                      onTap: null,
                    ),
                  const SizedBox(width: 8),
                ],
                _arrowButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: canNext,
                  onTap: () => onPageSelected(currentPage + 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return _pageButton(
      label: '',
      active: false,
      enabled: enabled,
      onTap: onTap,
      icon: icon,
    );
  }

  Widget _pageButton({
    required String label,
    required bool active,
    required bool enabled,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    final bg = active ? AppColors.primary : Colors.white;
    final borderColor = active ? AppColors.primary : const Color(0xFFD5DCE8);
    final textColor = active
        ? Colors.white
        : enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.15),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x332A62FF),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: icon != null
            ? Icon(icon, color: textColor, size: 22)
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ).copyWith(color: textColor),
              ),
      ),
    );
  }

  List<Object> _buildPages() {
    if (totalPages <= 6) {
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

    final sorted = raw.where((page) => page > 0 && page <= totalPages).toList()
      ..sort();
    final result = <Object>[];
    for (var index = 0; index < sorted.length; index++) {
      final page = sorted[index];
      result.add(page);
      if (index == sorted.length - 1) continue;
      final next = sorted[index + 1];
      if (next - page > 1) result.add('ellipsis');
    }
    return result;
  }
}
