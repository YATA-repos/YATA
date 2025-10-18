import "package:test/test.dart";

import "package:yata/core/constants/exceptions/exceptions.dart";
import "package:yata/core/utils/error_handler.dart";

void main() {
  group("ErrorHandler", () {
    test("handleError returns duplicate category message for unique constraint violation", () {
      final RepositoryException error = RepositoryException(
        RepositoryError.insertFailed,
        params: <String, String>{
          "error":
              'PostgrestException{code: 23505, message: duplicate key value violates unique constraint "material_categories_user_id_name_key"}',
        },
        code: "23505",
      );

      final String message = ErrorHandler.instance.handleError(error);

      expect(message, "このカテゴリ名は既に使用されています。別の名前を入力してください。");
    });

    test("handleError falls back to repository user message when not duplicate error", () {
      final RepositoryException error = RepositoryException(
        RepositoryError.insertFailed,
        params: <String, String>{"error": "Failed to insert due to network"},
      );

      final String message = ErrorHandler.instance.handleError(error);

      expect(message, RepositoryError.insertFailed.userMessage);
    });
  });
}
