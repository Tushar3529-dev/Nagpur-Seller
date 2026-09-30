import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';

/// An accepted order the seller is still scanning, and which of its items
/// (by order_item_id) are already verified.
class ScanSession {
  final PendingOrder order;
  final Set<int> verifiedItemIds;

  const ScanSession(this.order, this.verifiedItemIds);
}

/// Keeps accepted-but-not-prepared orders on the device. Once accepted, an
/// order drops out of the pending endpoint, so without this an app restart
/// mid-scan would lose the popup.
class ScanSessionStore {
  final String _boxName;

  ScanSessionStore({String boxName = 'incomingOrderScans'})
    : _boxName = boxName;
  static const _key = 'sessions';

  Future<List<ScanSession>> load() async {
    try {
      final box = await Hive.openBox(_boxName);
      final raw = box.get(_key);
      if (raw is! String) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [
        for (final entry in list.whereType<Map<String, dynamic>>())
          if (entry['order'] is Map<String, dynamic>)
            ScanSession(
              PendingOrder.fromJson(entry['order'] as Map<String, dynamic>),
              {
                for (final id in (entry['verified'] as List? ?? const []))
                  if (id is int) id,
              },
            ),
      ];
    } catch (e) {
      debugPrint('[ScanSessionStore] load failed: $e');
      return [];
    }
  }

  Future<void> save(Iterable<ScanSession> sessions) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(
        _key,
        jsonEncode([
          for (final session in sessions)
            {
              'order': session.order.toJson(),
              'verified': session.verifiedItemIds.toList(),
            },
        ]),
      );
    } catch (e) {
      debugPrint('[ScanSessionStore] save failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_key);
    } catch (e) {
      debugPrint('[ScanSessionStore] clear failed: $e');
    }
  }
}
