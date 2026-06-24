import '../../../core/router/route_names.dart';

enum ChatScope { customer, admin, store }

extension ChatScopeX on ChatScope {
  String get title {
    switch (this) {
      case ChatScope.admin:
        return 'Trung tâm chat';
      case ChatScope.store:
        return 'Tin nhắn shop';
      case ChatScope.customer:
        return 'Tin nhắn';
    }
  }

  String get newConversationPath {
    switch (this) {
      case ChatScope.admin:
        return RouteNames.adminChatNewPath;
      case ChatScope.store:
        return RouteNames.storeChatNewPath;
      case ChatScope.customer:
        return RouteNames.chatNewConversationPath;
    }
  }

  String detailPath(String conversationId) {
    switch (this) {
      case ChatScope.admin:
        return RouteNames.adminChatDetailPath.replaceAll(':id', conversationId);
      case ChatScope.store:
        return RouteNames.storeChatDetailPath.replaceAll(':id', conversationId);
      case ChatScope.customer:
        return RouteNames.chatDetailPath.replaceAll(':id', conversationId);
    }
  }
}
