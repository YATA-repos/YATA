import "package:flutter_test/flutter_test.dart";
import "package:yata/features/auth/models/user_model.dart";

void main() {
  group("UserRole", () {
    group("level property", () {
      test("管理者は最高レベルの権限を持つ", () {
        expect(UserRole.admin.level, 100);
      });

      test("店舗管理者は管理者より低いレベルの権限を持つ", () {
        expect(UserRole.manager.level, 80);
        expect(UserRole.manager.level, lessThan(UserRole.admin.level));
      });

      test("スタッフは管理者より低いレベルの権限を持つ", () {
        expect(UserRole.staff.level, 60);
        expect(UserRole.staff.level, lessThan(UserRole.manager.level));
      });

      test("閲覧者は最低レベルの権限を持つ", () {
        expect(UserRole.viewer.level, 40);
        expect(UserRole.viewer.level, lessThan(UserRole.staff.level));
      });
    });

    group("canAccess method", () {
      test("管理者は全てのロールにアクセスできる", () {
        const UserRole admin = UserRole.admin;

        expect(admin.canAccess(UserRole.admin), true);
        expect(admin.canAccess(UserRole.manager), true);
        expect(admin.canAccess(UserRole.staff), true);
        expect(admin.canAccess(UserRole.viewer), true);
      });

      test("店舗管理者は管理者以外にアクセスできる", () {
        const UserRole manager = UserRole.manager;

        expect(manager.canAccess(UserRole.admin), false);
        expect(manager.canAccess(UserRole.manager), true);
        expect(manager.canAccess(UserRole.staff), true);
        expect(manager.canAccess(UserRole.viewer), true);
      });

      test("スタッフは管理職以外にアクセスできる", () {
        const UserRole staff = UserRole.staff;

        expect(staff.canAccess(UserRole.admin), false);
        expect(staff.canAccess(UserRole.manager), false);
        expect(staff.canAccess(UserRole.staff), true);
        expect(staff.canAccess(UserRole.viewer), true);
      });

      test("閲覧者は閲覧者レベルのみアクセスできる", () {
        const UserRole viewer = UserRole.viewer;

        expect(viewer.canAccess(UserRole.admin), false);
        expect(viewer.canAccess(UserRole.manager), false);
        expect(viewer.canAccess(UserRole.staff), false);
        expect(viewer.canAccess(UserRole.viewer), true);
      });
    });

    group("displayName property", () {
      test("各ロールの表示名が正しい", () {
        expect(UserRole.admin.displayName, "システム管理者");
        expect(UserRole.manager.displayName, "店舗管理者");
        expect(UserRole.staff.displayName, "スタッフ");
        expect(UserRole.viewer.displayName, "閲覧者");
      });
    });

    group("fromValue method", () {
      test("有効な文字列値からUserRoleを取得できる", () {
        expect(UserRoleExtension.fromValue("admin"), UserRole.admin);
        expect(UserRoleExtension.fromValue("manager"), UserRole.manager);
        expect(UserRoleExtension.fromValue("staff"), UserRole.staff);
        expect(UserRoleExtension.fromValue("viewer"), UserRole.viewer);
      });

      test("無効な文字列値でnullを返す", () {
        expect(UserRoleExtension.fromValue("invalid"), isNull);
        expect(UserRoleExtension.fromValue(""), isNull);
      });
    });

    group("toJson method", () {
      test("JSON文字列に正しく変換される", () {
        expect(UserRole.admin.toJson(), "admin");
        expect(UserRole.manager.toJson(), "manager");
        expect(UserRole.staff.toJson(), "staff");
        expect(UserRole.viewer.toJson(), "viewer");
      });
    });

    group("fromJson method", () {
      test("有効なJSON文字列からUserRoleを復元できる", () {
        expect(UserRoleExtension.fromJson("admin"), UserRole.admin);
        expect(UserRoleExtension.fromJson("manager"), UserRole.manager);
        expect(UserRoleExtension.fromJson("staff"), UserRole.staff);
        expect(UserRoleExtension.fromJson("viewer"), UserRole.viewer);
      });

      test("無効なJSON文字列でArgumentErrorが発生する", () {
        expect(() => UserRoleExtension.fromJson("invalid"), throwsA(isA<ArgumentError>()));
      });
    });

    group("permission helper methods", () {
      test("isAdmin は管理者ロールのみtrueを返す", () {
        expect(UserRole.admin.isAdmin, true);
        expect(UserRole.manager.isAdmin, false);
        expect(UserRole.staff.isAdmin, false);
        expect(UserRole.viewer.isAdmin, false);
      });

      test("isManager は管理職ロールでtrueを返す", () {
        expect(UserRole.admin.isManager, true);
        expect(UserRole.manager.isManager, true);
        expect(UserRole.staff.isManager, false);
        expect(UserRole.viewer.isManager, false);
      });

      test("isStaff はスタッフ以上のロールでtrueを返す", () {
        expect(UserRole.admin.isStaff, true);
        expect(UserRole.manager.isStaff, true);
        expect(UserRole.staff.isStaff, true);
        expect(UserRole.viewer.isStaff, false);
      });
    });
  });
}
