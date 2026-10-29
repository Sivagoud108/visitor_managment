import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/visitor.dart';
import '../services/visitor_api_service.dart';

final visitorServiceProvider = Provider<VisitorApiService>(
  (ref) => VisitorApiService(),
);

final searchQueryProvider = StateProvider<String>((ref) => '');
final navIndexProvider = StateProvider<int>((ref) => 0);

final visitorsProvider =
    StateNotifierProvider<VisitorsNotifier, AsyncValue<List<Visitor>>>(
  (ref) => VisitorsNotifier(VisitorApiService()),
);

class VisitorsNotifier extends StateNotifier<AsyncValue<List<Visitor>>> {
  VisitorsNotifier(this._api) : super(const AsyncValue.loading()) {
    refresh();
  }

  final VisitorApiService _api;

  List<Visitor> get _current => state.value ?? const <Visitor>[];

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await _api.fetchVisitors();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Visitor> addVisitor(Visitor visitor) async {
    final created = await _api.createVisitor(visitor);
    state = AsyncValue.data([..._current, created]);
    return created;
  }

  Future<Visitor> updateVisitor(Visitor visitor) async {
    final updated = await _api.updateVisitor(visitor.id, visitor);
    _replaceLocal(updated);
    return updated;
  }

    Future<void> upsert(Visitor visitor) async {
    final current = _current;
    final index = current.indexWhere((v) => v.id == visitor.id);
    final next = [...current];
    if (index == -1) {
      next.add(visitor);
    } else {
      next[index] = visitor;
    }
    state = AsyncValue.data(next);
  }

  Future<void> deleteVisitor(String id) async {
    await _api.deleteVisitor(id);
    state = AsyncValue.data(
      _current.where((v) => v.id != id).toList(),
    );
  }

  Future<void> checkIn(String id) async {
    final current = await _api.fetchVisitorById(id);
    final updated = current.copyWith(
      status: VisitorStatus.checkedIn,
      checkInTime: DateTime.now(),
    );
    final saved = await _api.updateVisitor(id, updated);
    _replaceLocal(saved);
  }

  Future<void> checkOut(String id) async {
    final current = await _api.fetchVisitorById(id);
    final updated = current.copyWith(
      status: VisitorStatus.checkedOut,
      checkOutTime: DateTime.now(),
    );
    final saved = await _api.updateVisitor(id, updated);
    _replaceLocal(saved);
  }

  void _replaceLocal(Visitor updated) {
    state = AsyncValue.data([
      for (final v in _current) v.id == updated.id ? updated : v,
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Filtered list
// ─────────────────────────────────────────────────────────────
final filteredVisitorsProvider = Provider<AsyncValue<List<Visitor>>>((ref) {
  final visitors = ref.watch(visitorsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return visitors.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((v) {
      return v.name.toLowerCase().contains(query) ||
          v.mobile.toLowerCase().contains(query);
    }).toList();
  });
});

final visitorByIdProvider = FutureProvider.autoDispose.family<Visitor, String>(
  (ref, id) => VisitorApiService().fetchVisitorById(id),
);

class DashboardStats {
  const DashboardStats({
    required this.totalToday,
    required this.checkedIn,
    required this.checkedOutToday,
  });

  final int totalToday;
  final int checkedIn;
  final int checkedOutToday;

  static const empty = DashboardStats(
    totalToday: 0,
    checkedIn: 0,
    checkedOutToday: 0,
  );
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final visitors = ref.watch(visitorsProvider);

  return visitors.maybeWhen(
    data: (list) {
      final now = DateTime.now();
      bool isSameDay(DateTime d) =>
          d.year == now.year && d.month == now.month && d.day == now.day;

      final totalToday = list.where((v) => isSameDay(v.createdAt)).length;

      final checkedIn = list
          .where((v) => v.status == VisitorStatus.checkedIn)
          .length;

      final checkedOutToday = list
          .where((v) =>
              v.status == VisitorStatus.checkedOut &&
              v.checkOutTime != null &&
              isSameDay(v.checkOutTime!))
          .length;

      return DashboardStats(
        totalToday: totalToday,
        checkedIn: checkedIn,
        checkedOutToday: checkedOutToday,
      );
    },
    orElse: () => DashboardStats.empty,
  );
});