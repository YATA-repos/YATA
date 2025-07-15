import "package:flutter/material.dart";

import "../../../../shared/themes/app_colors.dart";
import "../../../../shared/themes/app_layout.dart";
import "../../../../shared/widgets/layout/responsive_container.dart";

enum OrderLayoutMode {
  split, // 左右分割
  tabs, // タブ切り替え（モバイル用）
  modal, // モーダル表示（モバイル用）
}

class OrderLayout extends StatefulWidget {
  const OrderLayout({
    required this.leftChild,
    required this.rightChild,
    super.key,
    this.leftFlex = 3,
    this.rightFlex = 2,
    this.mobileMode = OrderLayoutMode.tabs,
    this.leftTabLabel = "メニュー",
    this.rightTabLabel = "注文",
    this.showDivider = true,
    this.resizable = false,
    this.minLeftWidth = 300,
    this.minRightWidth = 250,
    this.leftHeader,
    this.rightHeader,
    this.onTabChanged,
    this.initialMobileTab = 0,
  });

  final Widget leftChild;
  final Widget rightChild;
  final int leftFlex;
  final int rightFlex;
  final OrderLayoutMode mobileMode;
  final String leftTabLabel;
  final String rightTabLabel;
  final bool showDivider;
  final bool resizable;
  final double minLeftWidth;
  final double minRightWidth;
  final Widget? leftHeader;
  final Widget? rightHeader;
  final ValueChanged<int>? onTabChanged;
  final int initialMobileTab;

  @override
  State<OrderLayout> createState() => _OrderLayoutState();
}

class _OrderLayoutState extends State<OrderLayout> with TickerProviderStateMixin {
  late TabController _tabController;
  double _dividerPosition = 0.6; // 60% left, 40% right

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialMobileTab);
    _tabController.addListener(_onTabChanged);

    // Calculate initial divider position from flex values
    final double totalFlex = (widget.leftFlex + widget.rightFlex).toDouble();
    _dividerPosition = widget.leftFlex / totalFlex;
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    widget.onTabChanged?.call(_tabController.index);
  }

  @override
  Widget build(BuildContext context) => BreakpointBuilder(
    builder: (BuildContext context, ResponsiveLayout layout, BoxConstraints constraints) {
      switch (layout) {
        case ResponsiveLayout.mobile:
          return _buildMobileLayout();
        case ResponsiveLayout.tablet:
        case ResponsiveLayout.desktop:
        case ResponsiveLayout.wide:
          return _buildDesktopLayout(constraints);
      }
    },
  );

  Widget _buildMobileLayout() {
    switch (widget.mobileMode) {
      case OrderLayoutMode.split:
        return _buildVerticalSplit();
      case OrderLayoutMode.tabs:
        return _buildTabLayout();
      case OrderLayoutMode.modal:
        return _buildModalLayout();
    }
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    if (widget.resizable) {
      return _buildResizableLayout(constraints);
    } else {
      return _buildFixedLayout();
    }
  }

  Widget _buildFixedLayout() => Row(
    children: <Widget>[
      Expanded(flex: widget.leftFlex, child: _buildLeftPanel()),
      if (widget.showDivider) _buildVerticalDivider(),
      Expanded(flex: widget.rightFlex, child: _buildRightPanel()),
    ],
  );

  Widget _buildResizableLayout(BoxConstraints constraints) {
    final double leftWidth = constraints.maxWidth * _dividerPosition;
    final double rightWidth = constraints.maxWidth * (1 - _dividerPosition);

    return Row(
      children: <Widget>[
        SizedBox(width: leftWidth, child: _buildLeftPanel()),
        if (widget.showDivider)
          GestureDetector(
            onPanUpdate: (DragUpdateDetails details) =>
                _updateDividerPosition(details, constraints),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: _buildResizableDivider(),
            ),
          ),
        SizedBox(width: rightWidth, child: _buildRightPanel()),
      ],
    );
  }

  void _updateDividerPosition(DragUpdateDetails details, BoxConstraints constraints) {
    final double newPosition =
        (details.globalPosition.dx - constraints.constrainWidth(0)) / constraints.maxWidth;
    final double minLeftRatio = widget.minLeftWidth / constraints.maxWidth;
    final double minRightRatio = widget.minRightWidth / constraints.maxWidth;

    setState(() {
      _dividerPosition = newPosition.clamp(minLeftRatio, 1 - minRightRatio);
    });
  }

  Widget _buildVerticalSplit() => Column(
    children: <Widget>[
      Expanded(child: _buildLeftPanel()),
      if (widget.showDivider) _buildHorizontalDivider(),
      Expanded(child: _buildRightPanel()),
    ],
  );

  Widget _buildTabLayout() => Column(
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedForeground,
          indicatorColor: AppColors.primary,
          tabs: <Widget>[
            Tab(text: widget.leftTabLabel),
            Tab(text: widget.rightTabLabel),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[_buildLeftPanel(), _buildRightPanel()],
        ),
      ),
    ],
  );

  Widget _buildModalLayout() => Stack(
    children: <Widget>[
      _buildLeftPanel(),
      Positioned(
        bottom: AppLayout.spacing4,
        right: AppLayout.spacing4,
        child: FloatingActionButton(
          onPressed: _showRightPanelModal,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          child: const Icon(Icons.shopping_cart),
        ),
      ),
    ],
  );

  void _showRightPanelModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController scrollController) => DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppLayout.spacing4)),
          ),
          child: Column(
            children: <Widget>[
              Container(
                padding: AppLayout.padding4,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      widget.rightTabLabel,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildRightPanel()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() => Container(
    color: AppColors.background,
    child: Column(
      children: <Widget>[
        if (widget.leftHeader != null)
          Container(
            width: double.infinity,
            padding: AppLayout.padding4,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: widget.leftHeader,
          ),
        Expanded(child: widget.leftChild),
      ],
    ),
  );

  Widget _buildRightPanel() => Container(
    color: AppColors.background,
    child: Column(
      children: <Widget>[
        if (widget.rightHeader != null)
          Container(
            width: double.infinity,
            padding: AppLayout.padding4,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: widget.rightHeader,
          ),
        Expanded(child: widget.rightChild),
      ],
    ),
  );

  Widget _buildVerticalDivider() => Container(width: 1, color: AppColors.border);

  Widget _buildHorizontalDivider() => Container(height: 1, color: AppColors.border);

  Widget _buildResizableDivider() => Container(
    width: 8,
    color: Colors.transparent,
    child: Center(child: Container(width: 1, color: AppColors.border)),
  );
}

class OrderLayoutController extends ChangeNotifier {
  OrderLayoutController({int currentTab = 0, bool isRightPanelVisible = true})
    : _currentTab = currentTab,
      _isRightPanelVisible = isRightPanelVisible;

  int _currentTab;
  bool _isRightPanelVisible;

  int get currentTab => _currentTab;
  bool get isRightPanelVisible => _isRightPanelVisible;

  void setCurrentTab(int tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void showRightPanel() {
    if (!_isRightPanelVisible) {
      _isRightPanelVisible = true;
      notifyListeners();
    }
  }

  void hideRightPanel() {
    if (_isRightPanelVisible) {
      _isRightPanelVisible = false;
      notifyListeners();
    }
  }

  void toggleRightPanel() {
    _isRightPanelVisible = !_isRightPanelVisible;
    notifyListeners();
  }
}
