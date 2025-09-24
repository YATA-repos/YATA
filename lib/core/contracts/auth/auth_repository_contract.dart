/// 認証リポジトリ契約（ジェネリック）
///
/// コアから機能層の型に依存しないため、ユーザープロファイル型 `U`
/// およびレスポンス型 `R` はジェネリックで受け取る。
abstract interface class AuthRepositoryContract<U, R> {
  Future<R> signInWithGoogle();
  Future<R> handleOAuthCallback(String callbackUrl);
  Future<U?> getCurrentUserProfile();
  bool isSessionValid();
  int getSessionRemainingSeconds();
  Future<R> refreshSession();
  Future<void> signOut({bool allDevices = false});
}
