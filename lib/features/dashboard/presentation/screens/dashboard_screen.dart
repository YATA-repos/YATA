import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/constants/constants.dart";
import "../../../../core/logging/logger_mixin.dart";
import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/widgets/navigation/mode_selector.dart";
import "../widgets/inventory_mode_view.dart";
import "../widgets/order_mode_view.dart";

/// ダッシュボード画面
///
/// Phase 3: 完全な機能実装（オーダー作成・在庫表示モード）
/// ModeSelector で切り替え可能な2つのモードを提供
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with LoggerMixin {
  @override
  String get componentName => "DashboardScreen";
  String selectedMode = "order";

  @override
  void initState() {
    super.initState();
    logDebug("ダッシュボード画面を初期化: 初期モード=$selectedMode");
  }

  @override
  Widget build(BuildContext context) => MainLayout(
      title: AppStrings.titleHome,
      child: Column(
        children: <Widget>[
          // モード選択
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: ModeSelector(
              selectedMode: selectedMode,
              onModeChanged: (String mode) {
                logDebug("ダッシュボードモードを変更: $selectedMode -> $mode");
                setState(() => selectedMode = mode);
              },
              options: const <ModeOption>[
                ModeOption(
                  id: "order",
                  label: "オーダー作成",
                  icon: LucideIcons.shoppingCart,
                  description: "メニュー選択・注文管理",
                ),
                ModeOption(
                  id: "inventory",
                  label: "在庫状況",
                  icon: LucideIcons.layers,
                  description: "リアルタイム在庫確認",
                ),
              ],
            ),
          ),

          // モード別コンテンツ
          Expanded(
            child: selectedMode == "order" 
                ? const OrderModeView() 
                : const InventoryModeView(),
          ),
        ],
      ),
    );
}
