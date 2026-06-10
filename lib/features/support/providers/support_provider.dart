import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/support_ticket_model.dart';
import '../data/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(supabaseClientProvider));
});

final userTicketsProvider = FutureProvider<List<SupportTicketModel>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return Future.value(const []);
  return ref.watch(supportRepositoryProvider).getTickets(userId);
});

final ticketDetailProvider = FutureProvider.family<SupportTicketModel?, String>(
  (ref, ticketId) =>
      ref.watch(supportRepositoryProvider).getTicketById(ticketId),
);

final adminTicketsProvider =
    NotifierProvider<
      AdminTicketsNotifier,
      AsyncValue<List<SupportTicketModel>>
    >(AdminTicketsNotifier.new);

final createTicketProvider =
    NotifierProvider<CreateTicketNotifier, AsyncValue<SupportTicketModel?>>(
      CreateTicketNotifier.new,
    );

class AdminTicketsNotifier
    extends Notifier<AsyncValue<List<SupportTicketModel>>> {
  late final SupportRepository _repository = ref.read(
    supportRepositoryProvider,
  );

  @override
  AsyncValue<List<SupportTicketModel>> build() => const AsyncValue.data([]);

  Future<void> load({String? status, String? priority}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getAdminTickets(status: status, priority: priority),
    );
  }
}

class CreateTicketNotifier extends Notifier<AsyncValue<SupportTicketModel?>> {
  late final SupportRepository _repository = ref.read(
    supportRepositoryProvider,
  );

  @override
  AsyncValue<SupportTicketModel?> build() => const AsyncValue.data(null);

  Future<void> submit({
    required String userId,
    String? orderId,
    required String subject,
    required String description,
    String priority = 'normal',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.createTicket(
        userId,
        orderId: orderId,
        subject: subject,
        description: description,
        priority: priority,
      ),
    );
  }
}
