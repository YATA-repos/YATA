import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/logging/logger_mixin.dart";

import "../../../../shared/widgets/cards/app_card.dart";
import "../../../../shared/widgets/common/loading_indicator.dart";
import "../../services/order_workflow_service.dart";

/// 材料発注画面
class MaterialOrderScreen extends ConsumerStatefulWidget {
  const MaterialOrderScreen({super.key});

  @override
  ConsumerState<MaterialOrderScreen> createState() => _MaterialOrderScreenState();
}

class _MaterialOrderScreenState extends ConsumerState<MaterialOrderScreen> with LoggerMixin {
  @override
  String get componentName => "MaterialOrderScreen";
  OrderCalculationResult? _orderResult;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, double> _adjustedQuantities = <String, double>{};

  @override
  void initState() {
    super.initState();
    logDebug("材料発注画面を初期化し、発注提案の計算を開始");
    _calculateOrderSuggestions();
  }

  /// 発注提案を計算
  Future<void> _calculateOrderSuggestions() async {
    logDebug("発注提案の計算を開始");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final OrderWorkflowService service = OrderWorkflowService(ref: ref as Ref);
      final OrderCalculationResult result = await service.calculateOrderSuggestions(
        "user-id", // 実際のユーザーIDを取得する必要がある
      );
      
      logInfo("発注提案の計算が完了: 総提案数=${result.totalSuggestions}, 緒急=${result.criticalCount}, 高優先度=${result.highPriorityCount}");
      setState(() {
        _orderResult = result;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logError("発注提案の計算中にエラーが発生", e, stackTrace);
      setState(() {
        _errorMessage = "発注提案の計算に失敗しました: $e";
        _isLoading = false;
      });
    }
  }

  /// 発注量を調整
  void _adjustQuantity(String materialId, double newQuantity) {
    logDebug("発注量を調整: materialId=$materialId, newQuantity=$newQuantity");
    setState(() {
      _adjustedQuantities[materialId] = newQuantity;
    });
  }

  /// 発注を実行
  Future<void> _executeOrders() async {
    if (_orderResult == null) {
      logWarning("発注実行: _orderResultがnullです");
      return;
    }

    logDebug("発注実行を開始: 総提案数=${_orderResult!.totalSuggestions}, 調整数=${_adjustedQuantities.length}");
    try {
      // 実際の発注処理を実装
      // 今回は簡単な通知のみ
      logInfo("発注処理を実行しました（シミュレーション）");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("発注処理を実行しました"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      logError("発注実行中にエラーが発生", e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("発注処理に失敗しました: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("材料発注"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: <Widget>[
          IconButton(
            onPressed: _calculateOrderSuggestions,
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: "再計算",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // エラーメッセージ表示
            if (_errorMessage != null)
              AppCard(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(LucideIcons.alertCircle, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // ローディング表示
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      LoadingIndicator(),
                      SizedBox(height: 16),
                      Text("発注提案を計算中..."),
                    ],
                  ),
                ),
              ),
            
            // 発注提案表示
            if (_orderResult != null && !_isLoading) ...<Widget>[
              // 統計情報
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "発注提案",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        _buildStatCard(
                          "総提案数",
                          "${_orderResult!.totalSuggestions}",
                          LucideIcons.package,
                          Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          "緊急",
                          "${_orderResult!.criticalCount}",
                          LucideIcons.alertTriangle,
                          Colors.red,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          "高優先度",
                          "${_orderResult!.highPriorityCount}",
                          LucideIcons.alertCircle,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 発注提案リスト
              if (_orderResult!.suggestions.isNotEmpty)
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "発注提案一覧",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _orderResult!.suggestions.length,
                            separatorBuilder: (BuildContext context, int index) => const Divider(),
                            itemBuilder: (BuildContext context, int index) {
                              final OrderSuggestion suggestion = _orderResult!.suggestions[index];
                              return _buildOrderSuggestionCard(suggestion);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 発注実行ボタン
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _orderResult!.hasOrderSuggestions ? _executeOrders : null,
                            icon: const Icon(LucideIcons.shoppingCart),
                            label: const Text("選択した項目を発注"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // 発注提案がない場合
              if (_orderResult!.suggestions.isEmpty)
                Expanded(
                  child: AppCard(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            LucideIcons.checkCircle,
                            size: 64,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "発注が必要な材料はありません",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "現在の在庫レベルは適切です",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

  /// 統計カードウィジェット
  Widget _buildStatCard(String label, String value, IconData icon, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );

  /// 発注提案カードウィジェット
  Widget _buildOrderSuggestionCard(OrderSuggestion suggestion) {
    final String materialId = suggestion.material.id!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _getPriorityColor(suggestion.priority).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: _getPriorityColor(suggestion.priority).withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ヘッダー
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      suggestion.material.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      suggestion.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(suggestion.priority),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityLabel(suggestion.priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 在庫情報
          Row(
            children: <Widget>[
              Expanded(
                child: _buildInfoItem(
                  "現在在庫",
                  "${suggestion.currentStock.toStringAsFixed(1)} ${suggestion.material.unitType.name}",
                  LucideIcons.package,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  "推定使用可能日数",
                  suggestion.estimatedUsageDays != null 
                      ? "${suggestion.estimatedUsageDays}日"
                      : "不明",
                  LucideIcons.calendar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 発注量調整
          Row(
            children: <Widget>[
              const Text("発注量: "),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: suggestion.suggestedOrderQuantity.toStringAsFixed(1),
                    suffix: Text(suggestion.material.unitType.name),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (String value) {
                    final double? quantity = double.tryParse(value);
                    if (quantity != null && quantity > 0) {
                      _adjustQuantity(materialId, quantity);
                    } else if (value.isNotEmpty) {
                      logWarning("無効な発注量が入力されました: $value");
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "提案: ${suggestion.suggestedOrderQuantity.toStringAsFixed(1)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 情報項目ウィジェット
  Widget _buildInfoItem(String label, String value, IconData icon) => Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );

  /// 優先度に応じた色を取得
  Color _getPriorityColor(OrderPriority priority) {
    switch (priority) {
      case OrderPriority.critical:
        return Colors.red;
      case OrderPriority.high:
        return Colors.orange;
      case OrderPriority.medium:
        return Colors.yellow.shade700;
      case OrderPriority.low:
        return Colors.blue;
    }
  }

  /// 優先度ラベルを取得
  String _getPriorityLabel(OrderPriority priority) {
    switch (priority) {
      case OrderPriority.critical:
        return "緊急";
      case OrderPriority.high:
        return "高";
      case OrderPriority.medium:
        return "中";
      case OrderPriority.low:
        return "低";
    }
  }
}