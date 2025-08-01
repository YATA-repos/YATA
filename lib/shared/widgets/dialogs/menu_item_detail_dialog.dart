import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../features/menu/models/menu_model.dart";
import "../../../shared/enums/ui_enums.dart";
import "../buttons/app_button.dart";
import "../cards/app_card.dart";

/// メニューアイテム詳細ダイアログ
class MenuItemDetailDialog extends StatelessWidget {
  const MenuItemDetailDialog({
    required this.item,
    super.key,
  });

  final MenuItem item;

  /// ダイアログを表示
  static Future<void> show(BuildContext context, MenuItem item) => showDialog<void>(
    context: context,
    builder: (BuildContext context) => MenuItemDetailDialog(item: item),
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "メニュー詳細",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // メニュー画像
            if (item.imageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: const Icon(
                  LucideIcons.utensils,
                  size: 48,
                ),
              ),
            const SizedBox(height: 16),

            // メニュー情報
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 商品名と価格
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "¥${item.price.toStringAsFixed(0)}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 販売状態
                  Row(
                    children: <Widget>[
                      Icon(
                        item.isAvailable ? LucideIcons.checkCircle : LucideIcons.xCircle,
                        size: 16,
                        color: item.isAvailable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.isAvailable ? "販売中" : "販売停止中",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: item.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 調理時間
                  Row(
                    children: <Widget>[
                      const Icon(LucideIcons.clock, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "調理時間: ${item.estimatedPrepTimeMinutes}分",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  // 商品説明
                  if (item.description != null && item.description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      "商品説明",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // アクションボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                AppButton(
                  text: "閉じる",
                  variant: ButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}