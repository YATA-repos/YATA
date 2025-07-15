import "package:flutter/material.dart";
import "package:lucide_icons/lucide_icons.dart";

/// クイックアクショングリッドウィジェット
///
/// ダッシュボードのクイックアクション（新規注文、カート、在庫など）を表示します。
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({required this.onActionTap, super.key});

  final void Function(String action) onActionTap;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "クイックアクション",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () => onActionTap("view_all_actions"),
              icon: const Icon(LucideIcons.moreHorizontal, size: 16),
              label: const Text("すべて"),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (BuildContext context, int index) => _buildActionCard(context, _quickActions[index]),
        ),
      ],
    );

  Widget _buildActionCard(BuildContext context, _QuickAction action) => Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => onActionTap(action.key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[action.color.withValues(alpha: 0.05), action.color.withValues(alpha: 0.02)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // アイコンコンテナ
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),

              const Spacer(),

              // タイトルとサブタイトル
              Text(
                action.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

  static final List<_QuickAction> _quickActions = <_QuickAction>[
    _QuickAction(
      key: "new_order",
      icon: LucideIcons.plus,
      title: "新規注文",
      subtitle: "注文を作成",
      color: Colors.blue,
    ),
    _QuickAction(
      key: "cart",
      icon: LucideIcons.shoppingCart,
      title: "カート",
      subtitle: "進行中の注文",
      color: Colors.green,
    ),
    _QuickAction(
      key: "inventory",
      icon: LucideIcons.package,
      title: "在庫確認",
      subtitle: "材料の状況",
      color: Colors.orange,
    ),
    _QuickAction(
      key: "menu",
      icon: LucideIcons.menuSquare,
      title: "メニュー",
      subtitle: "メニュー管理",
      color: Colors.purple,
    ),
    _QuickAction(
      key: "analytics",
      icon: LucideIcons.barChart3,
      title: "分析",
      subtitle: "売上・統計",
      color: Colors.indigo,
    ),
    _QuickAction(
      key: "settings",
      icon: LucideIcons.settings,
      title: "設定",
      subtitle: "システム設定",
      color: Colors.grey,
    ),
  ];
}

/// クイックアクションデータクラス
class _QuickAction {
  const _QuickAction({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
