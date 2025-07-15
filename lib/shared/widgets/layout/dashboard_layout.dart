import "package:flutter/material.dart";

import "../../themes/app_layout.dart";

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({
    required this.children,
    super.key,
    this.spacing = AppLayout.spacing4,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.padding,
    this.maxCrossAxisExtent,
    this.childAspectRatio = 1.0,
    this.crossAxisCount,
  });

  final List<Widget> children;
  final double spacing;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final double? maxCrossAxisExtent;
  final double childAspectRatio;
  final int? crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final EdgeInsetsGeometry responsivePadding =
        padding ?? AppLayout.getResponsivePadding(screenWidth);

    return SingleChildScrollView(padding: responsivePadding, child: _buildGrid(screenWidth));
  }

  Widget _buildGrid(double screenWidth) {
    final int columns = crossAxisCount ?? AppLayout.getGridColumns(screenWidth);
    final double spacing = crossAxisSpacing ?? this.spacing;
    final double mainSpacing = mainAxisSpacing ?? this.spacing;

    if (maxCrossAxisExtent != null) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent!,
          crossAxisSpacing: spacing,
          mainAxisSpacing: mainSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) => children[index],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) => children[index],
    );
  }
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.action,
    this.padding,
    this.spacing = AppLayout.spacing4,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? AppLayout.padding4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(context),
        SizedBox(height: spacing),
        ...children.map(
          (Widget child) => Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: child,
          ),
        ),
      ],
    ),
  );

  Widget _buildHeader(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: AppLayout.spacing1),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      if (action != null) action!,
    ],
  );
}

class ResponsiveDashboardLayout extends StatelessWidget {
  const ResponsiveDashboardLayout({
    required this.children,
    super.key,
    this.spacing = AppLayout.spacing4,
    this.padding,
    this.breakpoints = const DashboardBreakpoints(),
  });

  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final DashboardBreakpoints breakpoints;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final EdgeInsetsGeometry responsivePadding =
        padding ?? AppLayout.getResponsivePadding(screenWidth);

    return SingleChildScrollView(
      padding: responsivePadding,
      child: _buildResponsiveLayout(screenWidth),
    );
  }

  Widget _buildResponsiveLayout(double screenWidth) {
    if (screenWidth < breakpoints.tablet) {
      return _buildMobileLayout();
    } else if (screenWidth < breakpoints.desktop) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() => Column(
    children: children
        .map(
          (Widget child) => Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: spacing),
            child: child,
          ),
        )
        .toList(),
  );

  Widget _buildTabletLayout() => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double itemWidth = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children.map((Widget child) => SizedBox(width: itemWidth, child: child)).toList(),
      );
    },
  );

  Widget _buildDesktopLayout() {
    final List<List<Widget>> rows = <List<Widget>>[];
    final int itemsPerRow = 3;

    for (int i = 0; i < children.length; i += itemsPerRow) {
      final int end = (i + itemsPerRow > children.length) ? children.length : i + itemsPerRow;
      rows.add(children.sublist(i, end));
    }

    return Column(
      children: rows
          .map(
            (List<Widget> row) => Container(
              margin: EdgeInsets.only(bottom: spacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row
                    .map(
                      (Widget child) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: spacing),
                          child: child,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

class DashboardBreakpoints {
  const DashboardBreakpoints({
    this.tablet = AppLayout.breakpointTablet,
    this.desktop = AppLayout.breakpointDesktop,
    this.wide = AppLayout.breakpointWide,
  });

  final double tablet;
  final double desktop;
  final double wide;
}

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({
    required this.children,
    super.key,
    this.spacing = AppLayout.spacing4,
    this.padding,
    this.minItemWidth = 300.0,
    this.maxItemWidth = 400.0,
    this.itemHeight = 200.0,
  });

  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final double minItemWidth;
  final double maxItemWidth;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final EdgeInsetsGeometry responsivePadding =
        padding ?? AppLayout.getResponsivePadding(screenWidth);

    return SingleChildScrollView(padding: responsivePadding, child: _buildStaggeredGrid(context));
  }

  Widget _buildStaggeredGrid(BuildContext context) {
    final double availableWidth =
        MediaQuery.of(context).size.width - (padding?.horizontal ?? AppLayout.spacing8);
    final int crossAxisCount = (availableWidth / (minItemWidth + spacing)).floor();
    final double itemWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: children
          .map(
            (Widget child) => SizedBox(
              width: itemWidth.clamp(minItemWidth, maxItemWidth),
              height: itemHeight,
              child: child,
            ),
          )
          .toList(),
    );
  }
}
