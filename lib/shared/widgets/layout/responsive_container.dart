import "package:flutter/material.dart";

import "../../themes/app_layout.dart";

enum ResponsiveLayout { mobile, tablet, desktop, wide }

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.maxWidth,
    this.padding,
    this.margin,
    this.alignment,
    this.breakpoints,
    this.enableAutoWidth = true,
    this.enableAutoPadding = true,
    this.mobileChild,
    this.tabletChild,
    this.desktopChild,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final Map<ResponsiveLayout, double>? breakpoints;
  final bool enableAutoWidth;
  final bool enableAutoPadding;
  final Widget? mobileChild;
  final Widget? tabletChild;
  final Widget? desktopChild;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double screenWidth = constraints.maxWidth;
      final ResponsiveLayout layout = _getResponsiveLayout(screenWidth);
      final Widget currentChild = _getCurrentChild(layout);

      return Container(
        width: _getContainerWidth(screenWidth),
        padding: _getContainerPadding(screenWidth),
        margin: margin,
        alignment: alignment ?? Alignment.center,
        child: currentChild,
      );
    },
  );

  ResponsiveLayout _getResponsiveLayout(double screenWidth) {
    final Map<ResponsiveLayout, double> bp = breakpoints ?? _defaultBreakpoints;

    if (screenWidth >= bp[ResponsiveLayout.wide]!) {
      return ResponsiveLayout.wide;
    } else if (screenWidth >= bp[ResponsiveLayout.desktop]!) {
      return ResponsiveLayout.desktop;
    } else if (screenWidth >= bp[ResponsiveLayout.tablet]!) {
      return ResponsiveLayout.tablet;
    } else {
      return ResponsiveLayout.mobile;
    }
  }

  Widget _getCurrentChild(ResponsiveLayout layout) {
    switch (layout) {
      case ResponsiveLayout.mobile:
        return mobileChild ?? child;
      case ResponsiveLayout.tablet:
        return tabletChild ?? child;
      case ResponsiveLayout.desktop:
      case ResponsiveLayout.wide:
        return desktopChild ?? child;
    }
  }

  double? _getContainerWidth(double screenWidth) {
    if (!enableAutoWidth && maxWidth == null) {
      return null;
    }

    final double autoWidth = AppLayout.getContainerWidth(screenWidth);

    if (maxWidth != null) {
      return maxWidth! < autoWidth ? maxWidth : autoWidth;
    }

    return autoWidth;
  }

  EdgeInsetsGeometry? _getContainerPadding(double screenWidth) {
    if (!enableAutoPadding && padding == null) {
      return null;
    }

    final EdgeInsets autoPadding = AppLayout.getResponsivePadding(screenWidth);

    return padding ?? autoPadding;
  }

  Map<ResponsiveLayout, double> get _defaultBreakpoints => <ResponsiveLayout, double>{
    ResponsiveLayout.mobile: 0,
    ResponsiveLayout.tablet: AppLayout.breakpointMobile,
    ResponsiveLayout.desktop: AppLayout.breakpointDesktop,
    ResponsiveLayout.wide: AppLayout.breakpointWide,
  };
}

class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    required this.children,
    super.key,
    this.spacing = AppLayout.spacing4,
    this.runSpacing = AppLayout.spacing4,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.forceWrap = false,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool forceWrap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool shouldWrap = forceWrap || AppLayout.isMobile(constraints.maxWidth);

      if (shouldWrap) {
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: _getWrapAlignment(),
          crossAxisAlignment: _getWrapCrossAlignment(),
          children: children,
        );
      } else {
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: _addSpacing(children),
        );
      }
    },
  );

  List<Widget> _addSpacing(List<Widget> widgets) {
    if (widgets.length <= 1) {
      return widgets;
    }

    final List<Widget> spacedChildren = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      spacedChildren.add(widgets[i]);
      if (i < widgets.length - 1) {
        spacedChildren.add(SizedBox(width: spacing));
      }
    }
    return spacedChildren;
  }

  WrapAlignment _getWrapAlignment() {
    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }

  WrapCrossAlignment _getWrapCrossAlignment() {
    switch (crossAxisAlignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.center:
        return WrapCrossAlignment.center;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      case CrossAxisAlignment.stretch:
      case CrossAxisAlignment.baseline:
        return WrapCrossAlignment.start;
    }
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    super.key,
    this.spacing = AppLayout.spacing4,
    this.runSpacing = AppLayout.spacing4,
    this.columns,
    this.minItemWidth = 200,
    this.aspectRatio = 1.0,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;
  final double minItemWidth;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int columnCount = columns ?? _calculateColumns(constraints.maxWidth);

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) => children[index],
      );
    },
  );

  int _calculateColumns(double screenWidth) {
    if (columns != null) {
      return columns!;
    }

    final int autoColumns = ((screenWidth + spacing) / (minItemWidth + spacing)).floor();
    final int maxColumns = AppLayout.getGridColumns(screenWidth);

    return (autoColumns > 0 ? autoColumns : 1).clamp(1, maxColumns);
  }
}

class BreakpointBuilder extends StatelessWidget {
  const BreakpointBuilder({required this.builder, super.key, this.breakpoints});

  final Widget Function(BuildContext context, ResponsiveLayout layout, BoxConstraints constraints)
  builder;
  final Map<ResponsiveLayout, double>? breakpoints;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double screenWidth = constraints.maxWidth;
      final ResponsiveLayout layout = _getResponsiveLayout(screenWidth);

      return builder(context, layout, constraints);
    },
  );

  ResponsiveLayout _getResponsiveLayout(double screenWidth) {
    final Map<ResponsiveLayout, double> bp = breakpoints ?? _defaultBreakpoints;

    if (screenWidth >= bp[ResponsiveLayout.wide]!) {
      return ResponsiveLayout.wide;
    } else if (screenWidth >= bp[ResponsiveLayout.desktop]!) {
      return ResponsiveLayout.desktop;
    } else if (screenWidth >= bp[ResponsiveLayout.tablet]!) {
      return ResponsiveLayout.tablet;
    } else {
      return ResponsiveLayout.mobile;
    }
  }

  Map<ResponsiveLayout, double> get _defaultBreakpoints => <ResponsiveLayout, double>{
    ResponsiveLayout.mobile: 0,
    ResponsiveLayout.tablet: AppLayout.breakpointMobile,
    ResponsiveLayout.desktop: AppLayout.breakpointDesktop,
    ResponsiveLayout.wide: AppLayout.breakpointWide,
  };
}
