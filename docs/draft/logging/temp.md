対象：msg、fields（再帰深さ2の文字列値）、ctx、err.message、st（文字列部）

6.2 既定ルール（代表）

Email：[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}

電話（緩め）：\+?\d[\d -]{8,}\d

IP（修正適用）：正規表現ベースではなく InternetAddress.tryParse を優先。成功時にマスク。必要な補助として IPv4 の最小表現のみ正規表現を併用可。

クレカ（代表）：VISA/Master/Amex/Discover 等の BIN パターン（Luhn 検証は任意）

JWT：[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,}

トークン例：(sk-[A-Za-z0-9]{16,})|(AKIA[0-9A-Z]{16})

郵便番号（日本）：\b\d{3}-\d{4}\b

6.3 マスク方式

既定：[REDACTED]

任意：hash（SHA-256 + 起動時ソルト）、partial(keepTail=4) → *******1234

6.4 カスタム

customPatterns（正規表現）を設定で追加可能

allowListKeys：fields の特定キーは素通し（既定は空）