import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // CONNECTION — Invite Code System
  // ============================================================

  /// Look up a profile by invite code
  Future<Map<String, dynamic>?> findProfileByCode(String code) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('invite_code', code.toUpperCase())
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error finding profile by code: $e');
      return null;
    }
  }

  /// Connect two profiles as partners
  Future<bool> connectPartner(String partnerCode) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return false;

      // Find partner by code
      final partner = await findProfileByCode(partnerCode);
      if (partner == null) return false;

      final partnerId = partner['id'] as String;
      if (partnerId == currentUserId) return false; // Can't connect with yourself

      // Update both profiles to link them
      await _client.from('profiles').update({
        'partner_id': partnerId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUserId);

      await _client.from('profiles').update({
        'partner_id': currentUserId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', partnerId);

      return true;
    } catch (e) {
      debugPrint('Error connecting partner: $e');
      return false;
    }
  }

  /// Get partner profile
  Future<Map<String, dynamic>?> getPartnerProfile() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final myProfile = await _client
          .from('profiles')
          .select('partner_id')
          .eq('id', currentUserId)
          .maybeSingle();

      if (myProfile == null || myProfile['partner_id'] == null) return null;

      final partner = await _client
          .from('profiles')
          .select()
          .eq('id', myProfile['partner_id'])
          .maybeSingle();

      return partner;
    } catch (e) {
      debugPrint('Error getting partner profile: $e');
      return null;
    }
  }

  // ============================================================
  // DRAWINGS — Upload, Save & Fetch
  // ============================================================

  /// Upload drawing image to Supabase Storage
  Future<String?> uploadDrawing(Uint8List imageBytes) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '$userId/$fileName';

      await _client.storage.from('drawings').uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );

      final publicUrl = _client.storage.from('drawings').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading drawing: $e');
      return null;
    }
  }

  /// Save drawing record in database
  Future<Map<String, dynamic>?> saveDrawingRecord({
    required String imageUrl,
    required String recipientId,
  }) async {
    try {
      final senderId = _client.auth.currentUser?.id;
      if (senderId == null) return null;

      final response = await _client.from('drawings').insert({
        'sender_id': senderId,
        'recipient_id': recipientId,
        'image_url': imageUrl,
      }).select().single();

      return response;
    } catch (e) {
      debugPrint('Error saving drawing record: $e');
      return null;
    }
  }

  /// Send a drawing to partner (upload + save + auto-notify via trigger)
  Future<bool> sendDrawingToPartner(Uint8List imageBytes) async {
    try {
      // 1. Get partner
      final partner = await getPartnerProfile();
      if (partner == null) {
        debugPrint('No partner found');
        return false;
      }

      // 2. Upload image
      final imageUrl = await uploadDrawing(imageBytes);
      if (imageUrl == null) return false;

      // 3. Save record (trigger auto-creates notification)
      final record = await saveDrawingRecord(
        imageUrl: imageUrl,
        recipientId: partner['id'],
      );

      return record != null;
    } catch (e) {
      debugPrint('Error sending drawing to partner: $e');
      return false;
    }
  }

  /// Get drawing history (sent and received)
  Future<List<Map<String, dynamic>>> getDrawingHistory() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('drawings')
          .select('*, sender:profiles!sender_id(display_name, avatar_url)')
          .or('sender_id.eq.$userId,recipient_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching drawing history: $e');
      return [];
    }
  }

  // ============================================================
  // REALTIME — Listen for new drawings
  // ============================================================

  /// Stream of new drawings for the current user
  Stream<Map<String, dynamic>> listenForNewDrawings() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('drawings')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at')
        .map((rows) => rows.isNotEmpty ? rows.last : <String, dynamic>{})
        .where((row) => row.isNotEmpty);
  }

  /// Stream of new notifications for the current user
  Stream<List<Map<String, dynamic>>> listenForNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at');
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _client.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  /// Mark drawing as read
  Future<void> markDrawingRead(String drawingId) async {
    await _client.from('drawings').update({
      'is_read': true,
    }).eq('id', drawingId);
  }
}
