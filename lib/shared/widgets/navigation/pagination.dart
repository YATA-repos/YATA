import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../themes/app_colors.dart";
import "../../themes/app_text_theme.dart";

/// ページネーションウィジェット
///
/// ページ切り替えと表示件数選択をサポート
class AppPagination extends StatelessWidget {
  const AppPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.onItemsPerPageChanged,
    this.itemsPerPageOptions = const <int>[10, 20, 50, 100],
    this.showItemsPerPageSelector = true,
    this.showTotalInfo = true,
    this.maxVisiblePages = 5,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final void Function(int page) onPageChanged;
  final void Function(int itemsPerPage)? onItemsPerPageChanged;
  final List<int> itemsPerPageOptions;
  final bool showItemsPerPageSelector;
  final bool showTotalInfo;
  final int maxVisiblePages;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          // 総件数表示
          if (showTotalInfo) ...<Widget>[_buildTotalInfo(), const SizedBox(width: 16)],

          const Spacer(),

          // 表示件数選択
          if (showItemsPerPageSelector && onItemsPerPageChanged != null) ...<Widget>[
            _buildItemsPerPageSelector(),
            const SizedBox(width: 16),
          ],

          // ページング
          _buildPagination(),
        ],
      ),
    );

  Widget _buildTotalInfo() => Text(
    "全 $totalItems 件中 ${_getStartItem()}-${_getEndItem()} 件を表示",
    style: AppTextTheme.cardDescription,
  );

  Widget _buildItemsPerPageSelector() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text("表示件数:", style: AppTextTheme.cardDescription),
      const SizedBox(width: 8),
      DropdownButton<int>(
        value: itemsPerPage,
        onChanged: (int? value) {
          if (value != null) {
            onItemsPerPageChanged?.call(value);
          }
        },
        underline: const SizedBox(),
        style: AppTextTheme.cardDescription,
        items: itemsPerPageOptions.map((int value) => DropdownMenuItem<int>(value: value, child: Text("$value"))).toList(),
      ),
    ],
  );

  Widget _buildPagination() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // 最初のページ
      _buildPageButton(
        icon: LucideIcons.chevronFirst,
        onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
        tooltip: "最初のページ",
      ),

      const SizedBox(width: 4),

      // 前のページ
      _buildPageButton(
        icon: LucideIcons.chevronLeft,
        onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        tooltip: "前のページ",
      ),

      const SizedBox(width: 8),

      // ページ番号
      ..._buildPageNumbers(),

      const SizedBox(width: 8),

      // 次のページ
      _buildPageButton(
        icon: LucideIcons.chevronRight,
        onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
        tooltip: "次のページ",
      ),

      const SizedBox(width: 4),

      // 最後のページ
      _buildPageButton(
        icon: LucideIcons.chevronLast,
        onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
        tooltip: "最後のページ",
      ),
    ],
  );

  Widget _buildPageButton({
    IconData? icon,
    String? text,
    VoidCallback? onPressed,
    String? tooltip,
    bool isSelected = false,
  }) => Tooltip(
    message: tooltip ?? "",
    child: SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, size: 16)
            : Text(
                text ?? "",
                style: AppTextTheme.cardDescription.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
          foregroundColor: isSelected ? AppColors.primary : AppColors.mutedForeground,
          side: isSelected ? BorderSide(color: AppColors.primary.withValues(alpha: 0.3)) : null,
        ),
      ),
    ),
  );

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageNumbers = <Widget>[];
    final int start = _getStartPage();
    final int end = _getEndPage();

    // 最初のページが表示範囲外の場合は省略記号
    if (start > 1) {
      pageNumbers.add(
        _buildPageButton(
          text: "1",
          onPressed: () => onPageChanged(1),
          isSelected: currentPage == 1,
        ),
      );

      if (start > 2) {
        pageNumbers.add(
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("...")),
        );
      }
    }

    // 表示範囲のページ番号
    for (int i = start; i <= end; i++) {
      pageNumbers.add(
        _buildPageButton(
          text: "$i",
          onPressed: () => onPageChanged(i),
          isSelected: currentPage == i,
        ),
      );

      if (i < end) {
        pageNumbers.add(const SizedBox(width: 4));
      }
    }

    // 最後のページが表示範囲外の場合は省略記号
    if (end < totalPages) {
      if (end < totalPages - 1) {
        pageNumbers.add(
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("...")),
        );
      }

      pageNumbers.add(
        _buildPageButton(
          text: "$totalPages",
          onPressed: () => onPageChanged(totalPages),
          isSelected: currentPage == totalPages,
        ),
      );
    }

    return pageNumbers;
  }

  int _getStartPage() {
    final int half = maxVisiblePages ~/ 2;
    int start = currentPage - half;

    if (start < 1) {
      start = 1;
    } else if (start + maxVisiblePages - 1 > totalPages) {
      start = totalPages - maxVisiblePages + 1;
      if (start < 1) {
        start = 1;
      }
    }

    return start;
  }

  int _getEndPage() {
    final int start = _getStartPage();
    int end = start + maxVisiblePages - 1;

    if (end > totalPages) {
      end = totalPages;
    }

    return end;
  }

  int _getStartItem() {
    if (totalItems == 0) {
      return 0;
    }
    return (currentPage - 1) * itemsPerPage + 1;
  }

  int _getEndItem() {
    final int endItem = currentPage * itemsPerPage;
    return endItem > totalItems ? totalItems : endItem;
  }
}

/// ページネーション設定
class PaginationSettings {
  const PaginationSettings({
    this.itemsPerPage = 10,
    this.itemsPerPageOptions = const <int>[10, 20, 50, 100],
    this.maxVisiblePages = 5,
    this.showItemsPerPageSelector = true,
    this.showTotalInfo = true,
  });

  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final int maxVisiblePages;
  final bool showItemsPerPageSelector;
  final bool showTotalInfo;
}
