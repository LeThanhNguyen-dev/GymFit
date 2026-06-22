import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import 'models/support_ticket_model.dart';

class SupportRepository {
  const SupportRepository(this._client);

  final SupabaseClient _client;

  Future<List<SupportTicketModel>> getTickets(String userId) async {
    final rows = await _client
        .from(AppConstants.supportTicketsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map((row) => SupportTicketModel.fromJson(row)).toList();
  }

  Future<SupportTicketModel?> getTicketById(String ticketId) async {
    final row = await _client
        .from(AppConstants.supportTicketsTable)
        .select()
        .eq('id', ticketId)
        .maybeSingle();

    return row == null ? null : SupportTicketModel.fromJson(row);
  }

  Future<SupportTicketModel> createTicket(
    String userId, {
    String? orderId,
    required String subject,
    required String description,
    String category = 'other',
    String priority = 'medium',
  }) async {
    final row = await _client
        .from(AppConstants.supportTicketsTable)
        .insert({
          'user_id': userId,
          'order_id': orderId,
          'subject': subject.trim(),
          'description': description.trim(),
          'category': category,
          'priority': priority,
          'status': 'open',
        })
        .select()
        .single();

    return SupportTicketModel.fromJson(row);
  }

  Future<List<SupportTicketModel>> getAdminTickets({
    String? status,
    String? priority,
  }) async {
    final rows = await _client
        .from(AppConstants.supportTicketsTable)
        .select()
        .order('created_at', ascending: false);

    return rows
        .map((row) => SupportTicketModel.fromJson(row))
        .where((ticket) => status == null || ticket.status == status)
        .where((ticket) => priority == null || ticket.priority == priority)
        .toList();
  }

  Future<SupportTicketModel> adminReplyTicket(
    String ticketId,
    String reply,
    String newStatus,
  ) async {
    final now = DateTime.now().toIso8601String();
    final row = await _client
        .from(AppConstants.supportTicketsTable)
        .update({
          'admin_reply': reply.trim(),
          'status': newStatus,
          'replied_at': now,
          'updated_at': now,
        })
        .eq('id', ticketId)
        .select()
        .single();

    return SupportTicketModel.fromJson(row);
  }
}
