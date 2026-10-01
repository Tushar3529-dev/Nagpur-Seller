import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/repo/bags_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/widgets/add_bags_dialog.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class _FakeRepo extends BagsRepo {
  final List<List<String>> addCalls = [];
  List<String> alreadyUsed = const [];
  Object? addError;
  Completer<void>? addGate;

  @override
  Future<BulkAddBagsResult> addBags(List<String> barcodes) async {
    addCalls.add(barcodes);
    if (addGate != null) await addGate!.future;
    if (addError != null) throw addError!;
    final created = barcodes.where((c) => !alreadyUsed.contains(c)).toList();
    return BulkAddBagsResult(
      createdCount: created.length,
      createdBarcodes: created,
      duplicateBarcodes: barcodes.where(alreadyUsed.contains).toList(),
    );
  }
}

void main() {
  late _FakeRepo repo;
  late void Function(String code, Uint8List? image) scan;
  bool? closedWith;

  Future<void> open(WidgetTester tester) async {
    closedWith = null;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ScreenSizeBloc(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  closedWith = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Dialog(
                      child: AddBagsDialog(
                        repo: repo,
                        cameraBuilder: (onCode) {
                          scan = onCode;
                          return const SizedBox(
                            height: 100,
                            child: Text('camera'),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> scanAndSave(WidgetTester tester, String code) async {
    scan(code, null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & next'));
    await tester.pumpAndSettle();
  }

  setUp(() => repo = _FakeRepo());

  testWidgets('scans several bags, finishes, and adds them in one request', (
    tester,
  ) async {
    await open(tester);
    await scanAndSave(tester, 'BAG-1');
    expect(find.text('camera'), findsOneWidget);
    expect(find.text('1 bag in list'), findsOneWidget);
    await scanAndSave(tester, ' BAG-2 ');

    scan('BAG-3', null);
    await tester.pumpAndSettle();
    expect(find.text('Is this code correct?'), findsOneWidget);
    await tester.tap(find.text('Save and finish (3)'));
    await tester.pumpAndSettle();

    expect(find.text('Review 3 bags'), findsOneWidget);
    expect(find.text('BAG-1'), findsOneWidget);
    expect(find.text('BAG-2'), findsOneWidget);
    expect(find.text('BAG-3'), findsOneWidget);
    expect(repo.addCalls, isEmpty);

    await tester.tap(find.text('Confirm 3 bags'));
    await tester.pumpAndSettle();
    expect(repo.addCalls, [
      ['BAG-1', 'BAG-2', 'BAG-3'],
    ]);
    expect(find.text('3 bags added'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(closedWith, isTrue);
  });

  testWidgets('retake discards the scan instead of adding it', (tester) async {
    await open(tester);
    scan('BAG-WRONG', null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
    expect(find.textContaining('in list'), findsNothing);
  });

  testWidgets('ignores the bag just saved and flags other duplicates', (
    tester,
  ) async {
    await open(tester);
    await scanAndSave(tester, 'BAG-1');
    await scanAndSave(tester, 'BAG-2');

    // The camera still sees the bag that was just saved.
    scan('BAG-2', null);
    await tester.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
    expect(find.textContaining('already in your list'), findsNothing);

    scan('BAG-1', null);
    await tester.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
    expect(find.text('BAG-1 is already in your list.'), findsOneWidget);
    expect(find.text('2 bags in list'), findsOneWidget);
  });

  testWidgets('review list removes bags with the close button and swipe', (
    tester,
  ) async {
    await open(tester);
    await scanAndSave(tester, 'BAG-1');
    await scanAndSave(tester, 'BAG-2');
    await scanAndSave(tester, 'BAG-3');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove BAG-2'));
    await tester.pumpAndSettle();
    expect(find.text('BAG-2'), findsNothing);

    await tester.drag(find.text('BAG-1'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('BAG-1'), findsNothing);
    expect(find.text('Review 1 bag'), findsOneWidget);

    await tester.tap(find.text('Confirm 1 bag'));
    await tester.pumpAndSettle();
    expect(repo.addCalls, [
      ['BAG-3'],
    ]);
  });

  testWidgets('manual entry splits codes and skips ones already listed', (
    tester,
  ) async {
    await open(tester);
    await scanAndSave(tester, 'BAG-1');
    await tester.tap(find.byTooltip('Enter code manually'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to list'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a barcode'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'BAG-1, BAG-2;BAG-3\n');
    await tester.tap(find.text('Add to list'));
    await tester.pumpAndSettle();
    expect(find.text('Added 2 bags. 1 already in your list.'), findsOneWidget);
    expect(find.text('3 bags in list'), findsOneWidget);
  });

  testWidgets('reports barcodes the server skipped as already in use', (
    tester,
  ) async {
    repo.alreadyUsed = ['BAG-1'];
    await open(tester);
    await scanAndSave(tester, 'BAG-1');
    await scanAndSave(tester, 'BAG-2');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm 2 bags'));
    await tester.pumpAndSettle();

    expect(find.text('1 bag added'), findsOneWidget);
    expect(
      find.text('1 barcode is already in use and was skipped:'),
      findsOneWidget,
    );
    expect(find.text('BAG-1'), findsOneWidget);
  });

  testWidgets('a failed request keeps the list so it can be retried', (
    tester,
  ) async {
    repo.addError = ApiException('No Internet Connection');
    await open(tester);
    await scanAndSave(tester, 'BAG-1');
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm 1 bag'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No Internet Connection'), findsOneWidget);
    expect(find.text('BAG-1'), findsOneWidget);

    repo.addError = null;
    await tester.tap(find.text('Confirm 1 bag'));
    await tester.pumpAndSettle();
    expect(repo.addCalls, hasLength(2));
    expect(find.text('1 bag added'), findsOneWidget);
  });

  testWidgets('closing with scanned bags asks before discarding them', (
    tester,
  ) async {
    await open(tester);
    await scanAndSave(tester, 'BAG-1');

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard scanned bags?'), findsOneWidget);
    await tester.tap(find.text('Keep scanning'));
    await tester.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
    expect(closedWith, isNull);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(closedWith, isFalse);
    expect(repo.addCalls, isEmpty);
  });

  testWidgets('closing with an empty list closes straight away', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(closedWith, isFalse);
  });
}
