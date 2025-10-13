import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yata/shared/components/data_display/data_table.dart";
import "package:yata/shared/components/data_display/table_specs.dart";

void main() {
  group("YataDataTable", () {
    testWidgets("does not throw semantics assertions", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      final List<DataColumn> columns = <DataColumn>[
        const DataColumn(label: Text("在庫アイテム")),
        DataColumn(label: const Text("カテゴリ"), onSort: (_, __) {}),
        const DataColumn(label: Text("在庫状況")),
        DataColumn(label: const Text("ステータス"), onSort: (_, __) {}),
        DataColumn(label: const Text("調整"), onSort: (_, __) {}),
        DataColumn(label: const Text("更新"), onSort: (_, __) {}),
        const DataColumn(label: Text("操作")),
      ];

      final List<DataRow> rows = <DataRow>[
        DataRow(
          cells: <DataCell>[
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text("唐揚げ", style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text("メモ", maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const DataCell(Text("メイン")),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[Text("10個"), SizedBox(height: 4), Text("警告 5 / 危険 2")],
              ),
            ),
            DataCell(
              Wrap(
                spacing: 4,
                children: const <Widget>[
                  Chip(label: Text("警告")),
                  Chip(label: Text("処理中")),
                ],
              ),
            ),
            DataCell(
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[Text("+3"), SizedBox(height: 4), Text("適用後 13")],
                ),
              ),
            ),
            DataCell(Tooltip(message: "10分前", child: const Text("10分前"))),
            DataCell(
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: <Widget>[
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.save_outlined),
                      label: const Text("適用"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: YataDataTable(columns: columns, rows: rows),
            ),
          ),
        ),
      );

      await tester.pump();

      final Object? exception = tester.takeException();
      handle.dispose();

      expect(exception, isNull);
    });

    testWidgets("builds using specs without throwing", (WidgetTester tester) async {
      final List<YataTableColumnSpec> columns = <YataTableColumnSpec>[
        const YataTableColumnSpec(id: "item", label: Text("在庫アイテム")),
        const YataTableColumnSpec(id: "category", label: Text("カテゴリ")),
        const YataTableColumnSpec(id: "status", label: Text("ステータス")),
      ];

      final List<YataTableRowSpec> rows = <YataTableRowSpec>[
        YataTableRowSpec(
          id: "1",
          semanticLabel: "唐揚げ 在庫アイテム",
          cells: <YataTableCellSpec>[
            YataTableCellSpec.text(
              label: "唐揚げ",
              description: "メモ",
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            YataTableCellSpec.text(label: "メイン"),
            YataTableCellSpec.badges(badges: const <Widget>[Chip(label: Text("警告"))]),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YataDataTable.fromSpecs(columns: columns, rows: rows),
          ),
        ),
      );

      final Object? exception = tester.takeException();

      expect(exception, isNull);
    });

    testWidgets("falls back to onRowTap when rowSpec has no handler", (WidgetTester tester) async {
      int tappedIndex = -1;
      final List<YataTableColumnSpec> columns = <YataTableColumnSpec>[
        const YataTableColumnSpec(id: "name", label: Text("名前")),
      ];

      final List<YataTableRowSpec> rows = <YataTableRowSpec>[
        YataTableRowSpec(
          id: "row-a",
          cells: <YataTableCellSpec>[YataTableCellSpec.text(label: "Row A")],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YataDataTable.fromSpecs(
              columns: columns,
              rows: rows,
              onRowTap: (int index) => tappedIndex = index,
              shrinkWrap: true,
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text("Row A"));
      await tester.pumpAndSettle();

      expect(tappedIndex, 0);
    });
  });
}
