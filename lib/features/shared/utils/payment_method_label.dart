import "../../../core/constants/enums.dart";

/// PaymentMethod を日本語ラベルに変換するヘルパー。
String paymentMethodLabel(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return "現金";
    case PaymentMethod.card:
      return "カード";
    case PaymentMethod.other:
      return "その他";
  }
}
