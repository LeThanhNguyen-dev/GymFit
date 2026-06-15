import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/enums/database_enums.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(supabaseClientProvider));
});

final orderListProvider =
    NotifierProvider<OrderListNotifier, AsyncValue<List<OrderModel>>>(
      OrderListNotifier.new,
    );

final orderDetailProvider = FutureProvider.family<OrderModel?, String>((
  ref,
  orderId,
) {
  return ref.watch(orderRepositoryProvider).getOrderById(orderId);
});

final orderStatusHistoryProvider =
    FutureProvider.family<List<OrderStatusHistoryModel>, String>((
      ref,
      orderId,
    ) {
      return ref.watch(orderRepositoryProvider).getOrderStatusHistory(orderId);
    });

final orderSummaryProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return null;
  return ref.watch(orderRepositoryProvider).getOrderSummary(user.id);
});

class OrderListNotifier extends Notifier<AsyncValue<List<OrderModel>>> {
  String? _status;
  int _page = 0;
  bool _hasMore = true;

  String? get status => _status;
  bool get hasMore => _hasMore;

  @override
  AsyncValue<List<OrderModel>> build() {
    Future.microtask(load);
    return const AsyncValue.loading();
  }

  Future<void> setStatus(String? status) async {
    _status = status;
    _page = 0;
    _hasMore = true;
    await load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.value ?? const <OrderModel>[];
    final nextPage = _page + 1;
    final next = await _fetchPage(nextPage);
    _page = nextPage;
    _hasMore = next.length >= 20;
    state = AsyncValue.data([...current, ...next]);
  }

  Future<void> cancelOrder(String orderId) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) throw StateError('Ban can dang nhap.');
    await ref.read(orderRepositoryProvider).cancelOrder(orderId, user.id);
    await load();
  }

  Future<List<OrderModel>> _fetchPage(int page) {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) return Future.value(const <OrderModel>[]);
    return ref
        .read(orderRepositoryProvider)
        .getOrders(user.id, status: _status, page: page);
  }
}

final adminOrderListProvider =
    NotifierProvider<AdminOrderListNotifier, AsyncValue<List<OrderModel>>>(
      AdminOrderListNotifier.new,
    );

class AdminOrderListNotifier extends Notifier<AsyncValue<List<OrderModel>>> {
  String? _status;

  @override
  AsyncValue<List<OrderModel>> build() {
    Future.microtask(load);
    return const AsyncValue.loading();
  }

  Future<void> setStatus(String? status) async {
    _status = status;
    await load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).getAllOrders(status: _status),
    );
  }

  Future<void> updateStatus(
    String orderId,
    OrderStatus status, {
    String? note,
  }) async {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) throw StateError('Ban can dang nhap.');
    await ref
        .read(orderRepositoryProvider)
        .updateOrderStatus(orderId, status, user.id, note: note);
    await load();
  }
}
