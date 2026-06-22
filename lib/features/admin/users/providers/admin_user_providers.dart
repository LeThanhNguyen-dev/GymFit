import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';
import '../data/models/admin_user_model.dart';
import '../data/repositories/admin_user_repository.dart';

final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepository(ref.watch(supabaseClientProvider));
});

final adminUsersProvider =
    FutureProvider.family<({List<AdminUserModel> items, int totalCount}), AdminUsersFilter>((ref, filter) {
  return ref.watch(adminUserRepositoryProvider).getAllUsers(
        search: filter.search,
        role: filter.role,
        sellerStatus: filter.sellerStatus,
        banned: filter.banned,
        sortBy: filter.sortBy,
        ascending: filter.ascending,
        page: filter.page,
        pageSize: filter.pageSize,
      );
});

final adminUserDetailProvider = FutureProvider.family<AdminUserModel, String>((ref, userId) {
  return ref.watch(adminUserRepositoryProvider).getUserById(userId);
});

class AdminUsersFilter {
  const AdminUsersFilter({
    this.search,
    this.role,
    this.sellerStatus,
    this.banned,
    this.sortBy = 'created_at',
    this.ascending = false,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? search;
  final String? role;
  final String? sellerStatus;
  final bool? banned;
  final String sortBy;
  final bool ascending;
  final int page;
  final int pageSize;

  AdminUsersFilter copyWith({
    String? search,
    String? role,
    String? sellerStatus,
    bool? banned,
    String? sortBy,
    bool? ascending,
    int? page,
    int? pageSize,
  }) {
    return AdminUsersFilter(
      search: search ?? this.search,
      role: role ?? this.role,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      banned: banned ?? this.banned,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  AdminUsersFilter cleared() => const AdminUsersFilter();

  AdminUsersFilter withPage(int page) => copyWith(page: page);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUsersFilter &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          role == other.role &&
          sellerStatus == other.sellerStatus &&
          banned == other.banned &&
          sortBy == other.sortBy &&
          ascending == other.ascending &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode =>
      search.hashCode ^
      role.hashCode ^
      sellerStatus.hashCode ^
      banned.hashCode ^
      sortBy.hashCode ^
      ascending.hashCode ^
      page.hashCode ^
      pageSize.hashCode;
}
