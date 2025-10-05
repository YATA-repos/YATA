# YATAプロジェクト向けCSVエクスポート設計草案

本ドキュメントは、小規模飲食店・屋台向け在庫・注文管理システム「YATA」における、実務で本当に役立つCSVエクスポート設計の草案です。現場の会計・棚卸・メニュー改善・在庫最適化など、実際の運用ニーズに即したデータセット・カラム設計・計算式をまとめます。

---

## 1. 目的と前提

- **会計・税務対応**：売上・仕入・在庫の根拠台帳として必須
- **メニュー改善・価格見直し**：原価率・粗利・人気分析（メニュー工学）
- **発注・在庫最適化**：欠品・過剰在庫・廃棄抑制
- **オペ改善**：提供時間や仕込み計画の判断材料

---

## 2. コア台帳系エクスポート

### 2.1 売上明細（オーダー行）
- **用途**：売上計上、人気商品・時帯別分析
- **例ヘッダ**：
  business_date,order_id,line_id,channel,table_no,menu_item_id,menu_item_name,qty,unit_price,discount,tax_amount,line_total,ordered_at,served_at,canceled_flag
- **備考**：時刻はISO8601、金額は税込/税抜の方針を明記

### 2.2 仕入・入荷明細
- **用途**：売上原価計算、支払・取引先管理
- **例ヘッダ**：
  receipt_date,supplier_id,supplier_name,po_id,line_id,sku_id,sku_name,qty,unit_cost,ext_cost,tax_amount,batch_no,expiry_date,received_by

### 2.3 在庫トランザクション台帳
- **用途**：実地棚卸の照合、ロス追跡
- **例ヘッダ**：
  tx_time,sku_id,sku_name,tx_type(in|out|adjust|waste),qty,ref_type(order|receipt|count|prep),ref_id,lot_no,reason,performed_by

### 2.4 実地棚卸結果
- **用途**：月次締め、在庫評価
- **例ヘッダ**：
  count_date,sku_id,sku_name,book_qty,count_qty,delta_qty,unit_cost,inventory_value,checked_by

---

## 3. メニュー改善・価格検討

### 3.1 レシピ原価スナップショット
- **用途**：価格改定の根拠、時点原価の保存
- **例ヘッダ**：
  snapshot_date,menu_item_id,menu_item_name,recipe_version,ingredient_sku_id,ingredient_name,std_usage_qty,yield_rate,unit_cost,effective_unit_cost,portions_per_batch
- **計算式**：effective_unit_cost = unit_cost / yield_rate

### 3.2 メニュー工学用 集計（品目別日次）
- **用途**：人気×収益性マトリクス
- **例ヘッダ**：
  business_date,menu_item_id,menu_item_name,sales_qty,sales_amount,food_cost,contribution_margin,cm_rate,share_qty
- **主要指標**：
  - food_cost = Σ(effective_unit_cost × std_usage_qty) × sales_qty
  - contribution_margin = sales_amount - variable_cost
  - cm_rate = contribution_margin / sales_amount
  - share_qty = sales_qty / Σsales_qty

---

## 4. 発注最適化・サプライヤ管理

### 4.1 発注点・需要推定（SKU日次）
- **用途**：在庫切れ防止、発注最適化
- **例ヘッダ**：
  business_date,sku_id,avg_daily_demand,lead_time_days,demand_std,safety_stock,reorder_point
- **計算式**：
  - safety_stock = Z * demand_std * √lead_time_days
  - reorder_point = avg_daily_demand*lead_time_days + safety_stock

### 4.2 仕入価格履歴
- **用途**：原価上昇の見える化、価格交渉
- **例ヘッダ**：
  effective_date,supplier_id,sku_id,unit_cost,currency,notes

---

## 5. 廃棄・歩留まり・衛生

### 5.1 廃棄・ロスログ
- **用途**：廃棄原価・ロス率の算出
- **例ヘッダ**：
  waste_time,sku_id,sku_name,qty,unit_cost,reason(expired|prep_error|leftover|damage),lot_no,recorded_by
- **計算式**：廃棄原価 = qty × unit_cost

### 5.2 欠品・警告ログ
- **用途**：機会損失の把握、しきい値見直し
- **例ヘッダ**：
  event_time,sku_id,sku_name,stock_level,event_type(stockout|low_stock|expiry_soon),threshold,handled_by

---

## 6. オペ改善（スピードと体験）

### 6.1 提供リードタイム（キッチンKPI）
- **用途**：提供速度の可視化
- **例ヘッダ**：
  order_id,line_id,menu_item_id,ordered_at,started_at,ready_at,served_at,prep_seconds,hold_seconds,serve_seconds
- **計算式**：
  - prep_seconds = ready_at - started_at

---

## 7. 事前集計セット（多忙店舗向け）

- **日次売上サマリ**：business_date,total_sales,total_guests,avg_check,tax,discount
- **時帯別売上**：business_date,hour,sales,qty
- **カテゴリ別売上**：business_date,category,sales,qty,food_cost,cm
- **在庫回転サマリ（月次）**：month,sku_id,cogs,avg_inventory,turnover,days_on_hand
- **主要式**：
  - COGS = 期首在庫 + 仕入 - 期末在庫 - 廃棄
  - 在庫回転率 = COGS / 平均在庫高
  - Days on Hand ≈ 30 / 在庫回転率

---

## 8. 設計指針・注意点

- **キー**：org_id, location_id, business_date, order_id, line_id, sku_id, menu_item_id, supplier_id, lot_no などを共通採番
- **時刻**：YYYY-MM-DDTHH:MM:SS+09:00（ISO8601）で統一
- **数値**：小数点は.、通貨記号は列に含めない
- **エンコーディング**：UTF-8（Excel向けにBOM付も可）
- **辞書**：別途コード表CSV（category_master.csv等）を用意
- **PII**：個人情報は原則出さない。必要時はハッシュ化

---

## 9. 最小セット（V1推奨）

- 売上明細
- 仕入明細
- 在庫トランザクション
- 廃棄ログ
- メニュー工学用 集計（品目×日次）

これに「日次売上サマリ」「仕入価格履歴」を加えると、価格改定・原価上昇対応までカバー可能です。

---

## 10. まとめ

- 会計・棚卸の根拠台帳と、メニュー改善・在庫最適化に直結する少数のCSVに絞るのが現実的
- 明確な用途・再現可能な計算式を付記し、現場で“そのまま使える”形を目指す
- 既存スキーマがあれば、上記ヘッダへのマッピング表を作成すると運用がスムーズ

---

> 本草案はYATAプロジェクトの現状・将来像を踏まえ、実装・運用時の現実解を優先してまとめています。ご意見・現場要望は随時歓迎します。
