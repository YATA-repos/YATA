import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/providers/auth_providers.dart";
import "../../../../shared/enums/ui_enums.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/themes/themes.dart";
import "../../../../shared/widgets/buttons/app_button.dart";
import "../../models/order_model.dart";
import "../../models/order_ui_extensions.dart";
import "../providers/order_providers.dart";

/// 注文詳細画面
///
/// 個別の注文の詳細情報を表示し、ステータス変更・印刷機能を提供
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({
    required this.orderId,
    super.key,
  });

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  String? get userId => ref.read(currentUserProvider)?.id;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const MainLayout(
        title: "注文詳細",
        child: Center(child: Text("ユーザー情報が取得できません")),
      );
    }

    return ref
        .watch(orderWithItemsProvider(widget.orderId, userId!))
        .when(
          data: _buildMainContent,
          loading: () => const MainLayout(
            title: "注文詳細",
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object error, StackTrace stack) => MainLayout(
            title: "注文詳細",
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(LucideIcons.alertCircle, size: 64, color: AppColors.danger),
                  AppLayout.vSpacerDefault,
                  Text("注文詳細の取得に失敗しました"),
                  AppLayout.vSpacerSmall,
                  Text("$error"),
                  AppLayout.vSpacerDefault,
                  AppButton(
                    onPressed: () => context.pop(),
                    text: "戻る",
                    variant: ButtonVariant.outline,
                  ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _buildMainContent(Map<String, dynamic>? orderData) {
    if (orderData == null) {
      return const MainLayout(
        title: "注文詳細",
        child: Center(child: Text("注文データが見つかりません")),
      );
    }

    final Order order = orderData["order"] as Order;
    final List<OrderItem> items = orderData["items"] as List<OrderItem>? ?? <OrderItem>[];

    return MainLayout(
      title: "注文詳細 #${order.orderNumber}",
      actions: <Widget>[
        AppButton(
          onPressed: () => _handlePrint(order),
          variant: ButtonVariant.outline,
          size: ButtonSize.small,
          text: "印刷",
          icon: const Icon(LucideIcons.printer),
        ),
        const SizedBox(width: 8),
        AppButton(
          onPressed: () => _handleEdit(order),
          size: ButtonSize.small,
          text: "編集",
          icon: const Icon(LucideIcons.edit),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 注文概要カード
            _buildOrderSummaryCard(order),
            AppLayout.vSpacerDefault,

            // ステータス管理セクション
            _buildStatusManagementSection(order),
            AppLayout.vSpacerDefault,

            // 注文アイテムセクション
            _buildOrderItemsSection(items),
            AppLayout.vSpacerDefault,

            // アクションボタンセクション
            _buildActionButtonsSection(order),
          ],
        ),
      ),
    );
  }

  /// 注文概要カード
  Widget _buildOrderSummaryCard(Order order) => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("注文概要"),
            AppLayout.vSpacerDefault,
            _buildInfoRow("注文番号", order.orderNumber ?? "N/A"),
            AppLayout.vSpacerSmall,
            _buildInfoRow(
              "注文日時",
              "${order.orderedAt.year}/${order.orderedAt.month.toString().padLeft(2, '0')}/${order.orderedAt.day.toString().padLeft(2, '0')} ${order.orderedAt.hour.toString().padLeft(2, '0')}:${order.orderedAt.minute.toString().padLeft(2, '0')}",
            ),
            AppLayout.vSpacerSmall,
            _buildInfoRow("顧客名", order.displayCustomerName),
            AppLayout.vSpacerSmall,
            _buildInfoRow("合計金額", "¥${order.totalAmount.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );

  /// ステータス管理セクション
  Widget _buildStatusManagementSection(Order order) => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("ステータス管理"),
            AppLayout.vSpacerDefault,
            Row(
              children: <Widget>[
                Icon(
                  _getStatusIcon(order.status),
                  size: 24,
                  color: _getStatusColor(order.status),
                ),
                const SizedBox(width: 12),
                Text(
                  _getStatusText(order.status),
                ),
                const Spacer(),
                AppButton(
                  onPressed: () => _handleStatusChange(order),
                  variant: ButtonVariant.outline,
                  size: ButtonSize.small,
                  text: "ステータス変更",
                  icon: const Icon(LucideIcons.edit3),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  /// 注文アイテムセクション
  Widget _buildOrderItemsSection(List<OrderItem> items) => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("注文アイテム"),
            AppLayout.vSpacerDefault,
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text("注文アイテムがありません"),
                ),
              )
            else
              ...items.map(_buildOrderItemCard),
          ],
        ),
      ),
    );

  /// 注文アイテムカード
  Widget _buildOrderItemCard(OrderItem item) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.menuItemId, // TODO: メニューアイテム名を取得する実装が必要
                ),
                const SizedBox(height: 4),
                Text(
                  "数量: ${item.quantity}",
                ),
              ],
            ),
          ),
          Text(
            "¥${item.subtotal.toStringAsFixed(0)}",
          ),
        ],
      ),
    );

  /// アクションボタンセクション
  Widget _buildActionButtonsSection(Order order) => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("アクション"),
            AppLayout.vSpacerDefault,
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                AppButton(
                  onPressed: () => _handleCancel(order),
                  variant: ButtonVariant.outline,
                  size: ButtonSize.small,
                  text: "注文キャンセル",
                  icon: const Icon(LucideIcons.x),
                ),
                AppButton(
                  onPressed: () => _handleDuplicate(order),
                  variant: ButtonVariant.outline,
                  size: ButtonSize.small,
                  text: "複製注文",
                  icon: const Icon(LucideIcons.copy),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  /// 情報行ウィジェット
  Widget _buildInfoRow(String label, String value) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 100,
          child: Text(
            label,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value),
        ),
      ],
    );

  // ========== イベントハンドラー ==========

  /// 印刷処理
  void _handlePrint(Order order) {
    // TODO: 印刷機能の実装(優先度低め)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("印刷機能は現在開発中です"),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  /// 編集処理
  void _handleEdit(Order order) {
    // 完了済みまたはキャンセル済みの注文は編集できない
    if (order.status == OrderStatus.completed || 
        order.status == OrderStatus.cancelled || 
        order.status == OrderStatus.refunded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("この注文は編集できません"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _buildEditDialog(order),
    );
  }

  /// ステータス変更処理
  void _handleStatusChange(Order order) {
    final List<OrderStatus> availableStatuses = _getAvailableStatusTransitions(order.status);
    
    if (availableStatuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("このステータスからは変更できません"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _buildStatusChangeDialog(order, availableStatuses),
    );
  }

  /// 注文キャンセル処理
  void _handleCancel(Order order) {
    // 既にキャンセル済みまたは完了済みの注文はキャンセルできない
    if (order.status == OrderStatus.cancelled || 
        order.status == OrderStatus.completed || 
        order.status == OrderStatus.refunded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("この注文はキャンセルできません"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("注文キャンセル"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("注文 #${order.orderNumber} をキャンセルしますか？"),
            const SizedBox(height: 8),
            const Text(
              "この操作は取り消せません。キャンセルした注文は返金処理が必要になる場合があります。",
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("いいえ"),
          ),
          AppButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performStatusChange(order, OrderStatus.cancelled);
            },
            text: "キャンセル実行",
            variant: ButtonVariant.danger,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  /// 複製注文処理
  void _handleDuplicate(Order order) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("注文複製"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("注文 #${order.orderNumber} を複製しますか？"),
            const SizedBox(height: 8),
            const Text(
              "同じ内容で新しい注文が作成されます。ステータスは「待機中」になります。",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("キャンセル"),
          ),
          AppButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performOrderDuplicate(order);
            },
            text: "複製実行",
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  // ========== ユーティリティ関数 ==========

  /// 利用可能なステータス遷移を取得
  List<OrderStatus> _getAvailableStatusTransitions(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return <OrderStatus>[OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return <OrderStatus>[OrderStatus.preparing, OrderStatus.cancelled];
      case OrderStatus.preparing:
        return <OrderStatus>[OrderStatus.ready, OrderStatus.cancelled];
      case OrderStatus.ready:
        return <OrderStatus>[OrderStatus.delivered, OrderStatus.cancelled];
      case OrderStatus.delivered:
        return <OrderStatus>[OrderStatus.completed];
      case OrderStatus.cancelled:
        return <OrderStatus>[OrderStatus.refunded];
      case OrderStatus.completed:
      case OrderStatus.refunded:
        return <OrderStatus>[];
    }
  }

  /// ステータス変更ダイアログを構築
  Widget _buildStatusChangeDialog(Order order, List<OrderStatus> availableStatuses) => AlertDialog(
      title: const Text("ステータス変更"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("注文 #${order.orderNumber}"),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Text("現在のステータス: "),
              Icon(
                _getStatusIcon(order.status),
                size: 16,
                color: _getStatusColor(order.status),
              ),
              const SizedBox(width: 4),
              Text(
                order.status.displayName,
                style: TextStyle(color: _getStatusColor(order.status)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("変更先ステータス:"),
          const SizedBox(height: 8),
          ...availableStatuses.map(
            (OrderStatus status) => ListTile(
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              title: Text(status.displayName),
              onTap: () {
                Navigator.of(context).pop();
                _performStatusChange(order, status);
              },
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
      ],
    );

  /// 注文編集ダイアログを構築
  Widget _buildEditDialog(Order order) {
    final TextEditingController customerNameController = TextEditingController(text: order.customerName);
    final TextEditingController notesController = TextEditingController(text: order.notes);

    return AlertDialog(
      title: const Text("注文編集"),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("注文 #${order.orderNumber}"),
            const SizedBox(height: 16),
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: "顧客名",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "備考",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("キャンセル"),
        ),
        AppButton(
          onPressed: () {
            Navigator.of(context).pop();
            _performOrderEdit(
              order,
              customerNameController.text.trim(),
              notesController.text.trim(),
            );
          },
          text: "保存",
          size: ButtonSize.small,
        ),
      ],
    );
  }

  /// 注文編集を実行
  Future<void> _performOrderEdit(Order order, String customerName, String notes) async {
    try {
      // TODO: OrderServiceを使用して注文編集API呼び出し
      // await ref.read(orderServiceProvider).updateOrder(order.id!, {
      //   'customer_name': customerName.isEmpty ? null : customerName,
      //   'notes': notes.isEmpty ? null : notes,
      // });
      
      // プロバイダーをリフレッシュして画面を更新
      if (userId != null && order.id != null) {
        ref.invalidate(orderWithItemsProvider(order.id!, userId!));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("注文情報を更新しました"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("注文編集に失敗しました: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  /// 注文複製を実行
  Future<void> _performOrderDuplicate(Order order) async {
    try {
      // TODO: OrderServiceを使用して注文複製API呼び出し
      // final String newOrderId = await ref.read(orderServiceProvider).duplicateOrder(order.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("注文 #${order.orderNumber} を複製しました"),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: "新注文を表示",
            onPressed: () {
              // TODO: 新しい注文の詳細画面に遷移
              // context.go("/orders/$newOrderId");
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("注文複製に失敗しました: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  /// ステータス変更を実行
  Future<void> _performStatusChange(Order order, OrderStatus newStatus) async {
    try {
      // TODO: OrderServiceを使用してステータス変更API呼び出し
      // await ref.read(orderServiceProvider).updateOrderStatus(order.id!, newStatus);
      
      // プロバイダーをリフレッシュして画面を更新
      if (userId != null && order.id != null) {
        ref.invalidate(orderWithItemsProvider(order.id!, userId!));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ステータスを「${newStatus.displayName}」に変更しました"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ステータス変更に失敗しました: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  /// ステータスアイコン取得
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return LucideIcons.clock;
      case OrderStatus.preparing:
        return LucideIcons.chefHat;
      case OrderStatus.ready:
        return LucideIcons.checkCircle;
      case OrderStatus.completed:
        return LucideIcons.check;
      case OrderStatus.cancelled:
        return LucideIcons.x;
      case OrderStatus.confirmed:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.delivered:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.refunded:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// ステータス色取得
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.preparing:
        return AppColors.success;
      case OrderStatus.completed:
        return AppColors.primary;
      case OrderStatus.cancelled:
        return AppColors.danger;
      case OrderStatus.confirmed:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.delivered:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.refunded:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.ready:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// ステータステキスト取得
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return "注文受付";
      case OrderStatus.preparing:
        return "調理中";
      case OrderStatus.ready:
        return "完成";
      case OrderStatus.completed:
        return "完了";
      case OrderStatus.cancelled:
        return "キャンセル";
      case OrderStatus.confirmed:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.delivered:
        // TODO: Handle this case.
        throw UnimplementedError();
      case OrderStatus.refunded:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}