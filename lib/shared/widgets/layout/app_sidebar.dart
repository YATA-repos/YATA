import "package:flutter/material.dart";

import "../../constants/app_constants.dart";
import "../../themes/app_colors.dart";
import "../../themes/app_layout.dart";

class AppSidebar extends StatefulWidget {
  const AppSidebar({
    required this.items,
    super.key,
    this.isCollapsed = false,
    this.onCollapseChanged,
    this.currentPath,
    this.header,
    this.footer,
    this.width = 240,
    this.collapsedWidth = 64,
    this.showCollapseButton = true,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 0,
  });

  final List<SidebarItem> items;
  final bool isCollapsed;
  final ValueChanged<bool>? onCollapseChanged;
  final String? currentPath;
  final Widget? header;
  final Widget? footer;
  final double width;
  final double collapsedWidth;
  final bool showCollapseButton;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isCollapsed;
    _animationController = AnimationController(duration: AppConstants.animationNormal, vsync: this);
    _widthAnimation = Tween<double>(
      begin: widget.width,
      end: widget.collapsedWidth,
    ).animate(CurvedAnimation(parent: _animationController, curve: AppConstants.defaultCurve));

    if (_isCollapsed) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      _updateCollapseState(widget.isCollapsed);
    }
  }

  void _updateCollapseState(bool collapsed) {
    setState(() {
      _isCollapsed = collapsed;
    });

    if (collapsed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _toggleCollapse() {
    final bool newState = !_isCollapsed;
    _updateCollapseState(newState);
    widget.onCollapseChanged?.call(newState);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _widthAnimation,
    builder: (BuildContext context, Widget? child) {
      final double currentWidth = _widthAnimation.value;

      return Material(
        elevation: widget.elevation,
        color: widget.backgroundColor ?? AppColors.background,
        child: Container(
          width: currentWidth,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.background,
            border: Border(right: BorderSide(color: widget.borderColor ?? AppColors.border)),
          ),
          child: Column(
            children: <Widget>[
              if (widget.header != null) _buildHeader(),
              if (widget.showCollapseButton) _buildCollapseButton(),
              Expanded(child: _buildNavigationItems()),
              if (widget.footer != null) _buildFooter(),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: AppLayout.padding4,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: widget.borderColor ?? AppColors.border)),
    ),
    child: _isCollapsed ? const SizedBox(height: AppLayout.spacing8) : widget.header,
  );

  Widget _buildCollapseButton() => Container(
    padding: AppLayout.padding2,
    child: IconButton(
      onPressed: _toggleCollapse,
      icon: AnimatedRotation(
        turns: _isCollapsed ? 0.5 : 0,
        duration: AppConstants.animationNormal,
        child: const Icon(Icons.chevron_left),
      ),
      tooltip: _isCollapsed ? "サイドバーを展開" : "サイドバーを折りたたむ",
      color: AppColors.mutedForeground,
    ),
  );

  Widget _buildNavigationItems() => ListView.builder(
    padding: AppLayout.padding2,
    itemCount: widget.items.length,
    itemBuilder: (BuildContext context, int index) {
      final SidebarItem item = widget.items[index];

      if (item.isDivider) {
        return _buildDivider();
      }

      return _buildNavigationItem(item);
    },
  );

  Widget _buildDivider() => Container(
    margin: AppLayout.paddingVertical2,
    height: 1,
    color: widget.borderColor ?? AppColors.border,
  );

  Widget _buildNavigationItem(SidebarItem item) {
    final bool isActive = widget.currentPath == item.path;

    Widget itemWidget = Container(
      margin: AppLayout.padding1,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppLayout.radiusMd,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: AppLayout.radiusMd,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.spacing3,
              vertical: AppLayout.spacing3,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: AppLayout.radiusMd,
              border: isActive ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  item.icon,
                  size: AppLayout.iconSize,
                  color: isActive ? AppColors.primary : AppColors.mutedForeground,
                ),
                if (!_isCollapsed) ...<Widget>[
                  const SizedBox(width: AppLayout.spacing3),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: isActive ? AppColors.primary : AppColors.foreground,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (!_isCollapsed && item.badge != null) ...<Widget>[
                  const SizedBox(width: AppLayout.spacing2),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.spacing2,
                      vertical: AppLayout.spacing1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppLayout.radiusFull,
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                        color: AppColors.primaryForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (_isCollapsed && item.label.isNotEmpty) {
      itemWidget = Tooltip(message: item.label, child: itemWidget);
    }

    return itemWidget;
  }

  Widget _buildFooter() => Container(
    width: double.infinity,
    padding: AppLayout.padding4,
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: widget.borderColor ?? AppColors.border)),
    ),
    child: _isCollapsed ? const SizedBox(height: AppLayout.spacing8) : widget.footer,
  );
}

class SidebarItem {
  const SidebarItem({
    required this.icon,
    required this.label,
    this.path,
    this.onTap,
    this.badge,
    this.isDivider = false,
  });

  final IconData icon;
  final String label;
  final String? path;
  final VoidCallback? onTap;
  final String? badge;
  final bool isDivider;

  static const SidebarItem divider = SidebarItem(
    icon: Icons.more_horiz,
    label: "",
    isDivider: true,
  );
}

class SidebarController extends ChangeNotifier {
  SidebarController({bool isCollapsed = false, String? currentPath})
    : _isCollapsed = isCollapsed,
      _currentPath = currentPath;

  bool _isCollapsed;
  String? _currentPath;

  bool get isCollapsed => _isCollapsed;
  String? get currentPath => _currentPath;

  void setCollapsed(bool collapsed) {
    if (_isCollapsed != collapsed) {
      _isCollapsed = collapsed;
      notifyListeners();
    }
  }

  void toggleCollapse() {
    setCollapsed(!_isCollapsed);
  }

  void setCurrentPath(String? path) {
    if (_currentPath != path) {
      _currentPath = path;
      notifyListeners();
    }
  }
}
