class ChatContactQuery {
  const ChatContactQuery({
    this.search,
    this.roleFilter,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? search;
  final String? roleFilter;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is ChatContactQuery &&
        other.search == search &&
        other.roleFilter == roleFilter &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(search, roleFilter, page, pageSize);
}
