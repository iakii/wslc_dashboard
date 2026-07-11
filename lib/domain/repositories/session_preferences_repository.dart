/// Session 名称持久化抽象接口。
abstract class SessionPreferencesRepository {
  /// 获取 Dashboard 创建过的 session 名称列表。
  List<String> getDashboardSessionNames();

  /// 记录一个 Dashboard session 名称。
  Future<void> addDashboardSessionName(String name);

  /// 移除一个 Dashboard session 名称记录。
  Future<void> removeDashboardSessionName(String name);
}
