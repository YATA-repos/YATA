import 'package:flutter/material.dart';

/// 影の強さを表すエレベーショントークン。
class YataElevationTokens {
  const YataElevationTokens._();

  /// フラットな状態。影なし。
  static const List<BoxShadow> level0 = <BoxShadow>[
    BoxShadow(color: Colors.transparent, blurRadius: 0, offset: Offset.zero, spreadRadius: 0),
  ];

  /// カードやリストで使用する最小の影。
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(color: Color(0x1411182A), blurRadius: 12, offset: Offset(0, 3), spreadRadius: -1),
  ];

  /// ホバーカードやモーダルヘッダーに使用。
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(color: Color(0x1A11182A), blurRadius: 18, offset: Offset(0, 6), spreadRadius: -1),
  ];

  /// 浮き上がり感を強調する影。
  static const List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(color: Color(0x2611182A), blurRadius: 28, offset: Offset(0, 12), spreadRadius: -2),
  ];

  /// ダイアログやオーバーレイで使用する強い影。
  static const List<BoxShadow> level4 = <BoxShadow>[
    BoxShadow(color: Color(0x3311182A), blurRadius: 36, offset: Offset(0, 18), spreadRadius: -4),
  ];
}
