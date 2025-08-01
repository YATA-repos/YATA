import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:lucide_icons/lucide_icons.dart";

import "../../../../core/utils/responsive_helper.dart";
import "../../../../shared/layouts/main_layout.dart";
import "../../../../shared/widgets/navigation/mode_selector.dart";
import "../widgets/menu_display_view.dart";
import "../widgets/menu_management_view.dart";

/// メニュー管理画面
///
/// ModeSelector で切り替え可能な2つのモードを提供
/// - メニュー表示モード: カード形式でメニュー閲覧・管理
/// - メニュー管理モード: テーブル形式で詳細管理
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String selectedMode = "display";

  @override
  Widget build(BuildContext context) => MainLayout(
      title: "メニュー管理",
      child: Column(
        children: <Widget>[
          // モード選択
          Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: ModeSelector(
              selectedMode: selectedMode,
              onModeChanged: (String mode) => setState(() => selectedMode = mode),
              options: const <ModeOption>[
                ModeOption(
                  id: "display",
                  label: "メニュー表示",
                  icon: LucideIcons.utensils,
                  description: "メニューの閲覧・販売可否切り替え",
                ),
                ModeOption(
                  id: "management",
                  label: "詳細管理",
                  icon: LucideIcons.settings,
                  description: "テーブル形式で一括管理",
                ),
              ],
            ),
          ),

          // モード別コンテンツ
          Expanded(
            child: selectedMode == "display" ? const MenuDisplayView() : const MenuManagementView(),
          ),
        ],
      ),
    );
}