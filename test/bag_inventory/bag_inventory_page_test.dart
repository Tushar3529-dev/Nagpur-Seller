import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/repo/bags_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/view/bag_inventory_page.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class _FakeRepo extends BagsRepo {
  final List<Bag> bags;
  final List<String?> statusCalls = [];
  final List<int> deleteCalls = [];
  Object? deleteError;

  _FakeRepo(this.bags);

  @override
  Future<BagsPage> getBags({
    int page = 1,
    int perPage = 25,
    String? status,
    String? search,
  }) async {
    statusCalls.add(status);
    final items = bags
        .where((b) => status == null || b.status == status)
        .where((b) => search == null || b.barcode.contains(search))
        .toList();
    return BagsPage(
      items: items,
      currentPage: 1,
      lastPage: 1,
      total: items.length,
    );
  }

  @override
  Future<void> deleteBag(int id) async {
    deleteCalls.add(id);
    if (deleteError != null) throw deleteError!;
    bags.removeWhere((b) => b.id == id);
  }
}

void main() {
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo([
      Bag(
        id: 33,
        barcode: 'BAG-000033',
        status: Bag.available,
        createdAt: DateTime.utc(2026, 10, 1, 9),
      ),
      Bag(
        id: 34,
        barcode: 'BAG-000034',
        status: Bag.assigned,
        sellerOrderId: 701,
        orderNumber: 'NM-20261001-AB3XK9ZM',
        createdAt: DateTime.utc(2026, 10, 1, 9, 1),
      ),
    ]);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ScreenSizeBloc(),
        child: MaterialApp(home: BagInventoryPage(repo: repo)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('status chips reload the list with that filter', (tester) async {
    await open(tester);
    expect(find.text('2 bags'), findsOneWidget);
    expect(find.text('BAG-000033'), findsOneWidget);
    expect(find.text('BAG-000034'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Assigned'));
    await tester.pumpAndSettle();
    expect(repo.statusCalls.last, Bag.assigned);
    expect(find.text('1 assigned bag'), findsOneWidget);
    expect(find.text('BAG-000033'), findsNothing);
    expect(find.text('NM-20261001-AB3XK9ZM'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(repo.statusCalls.last, isNull);
    expect(find.text('2 bags'), findsOneWidget);
  });

  testWidgets('assigned bags show a lock instead of edit and delete', (
    tester,
  ) async {
    await open(tester);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    await tester.tap(find.byIcon(Icons.lock_outline));
    await tester.pump();
    expect(
      find.textContaining('assigned to order NM-20261001-AB3XK9ZM'),
      findsOneWidget,
    );
  });

  testWidgets('delete asks first, then removes the bag', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete bag?'), findsOneWidget);
    expect(repo.deleteCalls, isEmpty);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repo.deleteCalls, [33]);
    expect(find.text('BAG-000033'), findsNothing);
    expect(find.text('1 bag'), findsOneWidget);
  });

  testWidgets('a 409 on delete explains the bag is now assigned', (
    tester,
  ) async {
    repo.deleteError = ApiException('Bag is assigned.', statusCode: 409);
    await open(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('now assigned to an order'), findsOneWidget);
  });
}
