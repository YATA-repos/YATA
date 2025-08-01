import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "error_widget.dart";
import "loading_indicator.dart";

/// 非同期状態ビルダー
///
/// AsyncValueの状態に応じて適切なウィジェットを表示します。
/// ローディング、エラー、データ状態を統一的に処理できます。
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.loadingMessage,
    this.skipLoadingOnRefresh = false,
    this.skipError = false,
    super.key,
  });

  /// AsyncValueの値
  final AsyncValue<T> value;

  /// データ状態でのウィジェット構築
  final Widget Function(T data) data;

  /// ローディング状態でのウィジェット（オプション）
  final Widget? loading;

  /// エラー状態でのウィジェット構築（オプション）
  final Widget Function(Object error, StackTrace? stackTrace)? error;

  /// ローディングメッセージ
  final String? loadingMessage;

  /// リフレッシュ時のローディングをスキップするか
  final bool skipLoadingOnRefresh;

  /// エラー表示をスキップするか
  final bool skipError;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () {
      if (skipLoadingOnRefresh && value.hasValue) {
        return data(value.requireValue);
      }
      return loading ?? LoadingIndicator(message: loadingMessage);
    },
    error: (Object err, StackTrace stack) {
      if (skipError) {
        return const SizedBox.shrink();
      }
      return error?.call(err, stack) ??
          ErrorStateHelper.buildErrorWidget(
            error: err,
            onRetry: () => value.hasValue ? null : () {},
          );
    },
    data: data,
  );
}

/// 簡単な非同期状態ビルダー
///
/// より簡潔な記述でAsyncValueを処理できます。
class SimpleAsyncBuilder<T> extends StatelessWidget {
  const SimpleAsyncBuilder({
    required this.value,
    required this.builder,
    this.loadingMessage,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) => AsyncStateBuilder<T>(
    value: value,
    data: (T data) => builder(context, data),
    loadingMessage: loadingMessage,
  );
}

/// リスト用非同期状態ビルダー
///
/// リストデータに特化した表示を提供します。
/// 空の状態も自動的に処理します。
class AsyncListBuilder<T> extends StatelessWidget {
  const AsyncListBuilder({
    required this.value,
    required this.itemBuilder,
    this.emptyBuilder,
    this.loadingMessage,
    this.emptyTitle = "データがありません",
    this.emptyMessage,
    super.key,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(BuildContext context, List<T> items) itemBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final String? loadingMessage;
  final String emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) => AsyncStateBuilder<List<T>>(
    value: value,
    loadingMessage: loadingMessage,
    data: (List<T> items) {
      if (items.isEmpty) {
        return emptyBuilder?.call(context) ??
            EmptyStateWidget(title: emptyTitle, message: emptyMessage);
      }
      return itemBuilder(context, items);
    },
  );
}

/// Futureベースの状態ビルダー
///
/// FutureProvider以外のFutureでも使用できる汎用的なビルダーです。
class FutureStateBuilder<T> extends StatelessWidget {
  const FutureStateBuilder({
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.loadingMessage,
    super.key,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return loadingBuilder?.call(context) ?? LoadingIndicator(message: loadingMessage);
      }

      if (snapshot.hasError) {
        return errorBuilder?.call(context, snapshot.error!) ??
            ErrorStateHelper.buildErrorWidget(error: snapshot.error!);
      }

      if (snapshot.hasData) {
        return builder(context, snapshot.data as T);
      }

      return const EmptyStateWidget();
    },
  );
}
