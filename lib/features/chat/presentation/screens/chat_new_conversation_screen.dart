import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/chat_contact_model.dart';
import '../../data/models/chat_contact_query.dart';
import '../../providers/chat_providers.dart';
import '../chat_scope.dart';

class ChatNewConversationScreen extends ConsumerStatefulWidget {
  const ChatNewConversationScreen({
    super.key,
    required this.scope,
  });

  final ChatScope scope;

  @override
  ConsumerState<ChatNewConversationScreen> createState() => _ChatNewConversationScreenState();
}

class _ChatNewConversationScreenState extends ConsumerState<ChatNewConversationScreen> {
  final _searchController = TextEditingController();
  String? _roleFilter;
  String? _creatingUserId;

  @override
  void initState() {
    super.initState();
    _roleFilter = _defaultRoleFilter(widget.scope);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ChatContactQuery(
      search: _searchController.text.trim(),
      roleFilter: _roleFilter,
    );
    final contactsAsync = ref.watch(chatContactsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn người để chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc email',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableFilters(widget.scope).map((filter) {
                  final selected = _roleFilter == filter.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _roleFilter = selected ? null : filter.value;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: contactsAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không tìm thấy liên hệ phù hợp để bắt đầu cuộc trò chuyện.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: result.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = result.items[index];
                    final isCreating = _creatingUserId == contact.id;
                    return Card(
                      child: ListTile(
                        onTap: isCreating ? null : () => _startConversation(contact),
                        leading: CircleAvatar(child: Text(contact.initials)),
                        title: Text(contact.fullName),
                        subtitle: Text('${contact.roleDisplay} • ${contact.email}'),
                        trailing: isCreating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không thể tải danh bạ chat: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startConversation(ChatContactModel contact) async {
    setState(() => _creatingUserId = contact.id);
    try {
      final conversationId = await ref
          .read(chatRepositoryProvider)
          .createOrGetDirectConversation(contact.id);
      if (!mounted) return;
      context.push(widget.scope.detailPath(conversationId), extra: contact);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo cuộc trò chuyện: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingUserId = null);
      }
    }
  }

  static String? _defaultRoleFilter(ChatScope scope) {
    switch (scope) {
      case ChatScope.customer:
        return 'admin';
      case ChatScope.store:
        return 'customer';
      case ChatScope.admin:
        return null;
    }
  }

  static List<_RoleFilter> _availableFilters(ChatScope scope) {
    switch (scope) {
      case ChatScope.customer:
        return const [
          _RoleFilter('admin', 'Admin'),
          _RoleFilter('storeowner', 'Chủ shop'),
        ];
      case ChatScope.store:
        return const [
          _RoleFilter('customer', 'Khách hàng'),
          _RoleFilter('admin', 'Admin'),
        ];
      case ChatScope.admin:
        return const [
          _RoleFilter('customer', 'Khách hàng'),
          _RoleFilter('storeowner', 'Chủ shop'),
          _RoleFilter('admin', 'Admin'),
        ];
    }
  }
}

class _RoleFilter {
  const _RoleFilter(this.value, this.label);

  final String value;
  final String label;
}
