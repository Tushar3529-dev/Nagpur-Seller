import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/repo/dispatch_repo.dart';

Map<String, dynamic> dashboardJson() =>
    jsonDecode(r'''{
  "success": true,
  "message": "Dispatch dashboard fetched successfully.",
  "data": {
    "summary": {
      "ready_orders": 2,
      "no_nearby_riders": 1,
      "assigned_orders": 1
    },
    "orders": [
      {
        "order_id": 183,
        "order_number": "NM-20261025-AB3XK9ZM",
        "status": "no_nearby_riders",
        "delivery_boy_id": null,
        "delivery_boy_name": null,
        "pickup": "Sharma Kirana",
        "pickup_store_id": 12,
        "pickup_latitude": "21.14580000",
        "pickup_longitude": "79.08820000",
        "nearby_available_riders": 0,
        "bag_barcode": "BAG-000183",
        "created_at": "2026-10-25T10:00:00+00:00"
      },
      {
        "order_id": 184,
        "order_number": "NM-20261025-CD4LM2PQ",
        "status": "awaiting_rider_acceptance",
        "delivery_boy_id": 5,
        "delivery_boy_name": "Rider Name",
        "pickup": "Sharma Kirana",
        "pickup_store_id": 12,
        "pickup_latitude": "21.14580000",
        "pickup_longitude": "79.08820000",
        "nearby_available_riders": 2,
        "bag_barcode": "BAG-000184",
        "created_at": "2026-10-25T10:01:00+00:00"
      }
    ]
  }
}''')
        as Map<String, dynamic>;
Map<String, dynamic> availabilityJson() =>
    jsonDecode(r'''{
  "success": true,
  "message": "Rider availability fetched successfully.",
  "data": {
    "summary": {
      "active_riders": 4,
      "available_riders_in_radius": 2,
      "inactive_riders": 3
    },
    "riders": [
      {
        "id": 5,
        "name": "Rider Name",
        "status": "active",
        "verification_status": "verified",
        "delivery_zone": "Dharampeth",
        "is_available_in_radius": true,
        "nearest_pickup_distance_m": 84,
        "location_reported_at": "2026-10-25T10:00:00+00:00",
        "location_age_seconds": 18,
        "unavailable_reason": null
      },
      {
        "id": 6,
        "name": "Another Rider",
        "status": "active",
        "verification_status": "verified",
        "delivery_zone": "Dharampeth",
        "is_available_in_radius": false,
        "nearest_pickup_distance_m": null,
        "location_reported_at": "2026-10-25T09:54:00+00:00",
        "location_age_seconds": 378,
        "unavailable_reason": "location_stale"
      }
    ]
  }
}''')
        as Map<String, dynamic>;

class FakeDispatchRepo extends DispatchRepo {
  DispatchDashboard dashboard = DispatchDashboard.fromJson(dashboardJson());
  RiderAvailability availability = RiderAvailability.fromJson(
    availabilityJson(),
  );
  Object? dashboardError;
  Object? availabilityError;
  Object? writeError;
  Completer<DispatchDashboard>? dashboardGate;
  Completer<RiderAvailability>? availabilityGate;
  Completer<void>? writeGate;
  int dashboardCalls = 0;
  int availabilityCalls = 0;
  int writeCalls = 0;
  @override
  Future<DispatchDashboard> getDashboard() async {
    dashboardCalls++;
    if (dashboardGate != null) return dashboardGate!.future;
    if (dashboardError != null) throw dashboardError!;
    return dashboard;
  }

  @override
  Future<RiderAvailability> getRiderAvailability() async {
    availabilityCalls++;
    if (availabilityGate != null) return availabilityGate!.future;
    if (availabilityError != null) throw availabilityError!;
    return availability;
  }

  @override
  Future<int> markSelfDelivery(int orderId) async {
    writeCalls++;
    if (writeGate != null) await writeGate!.future;
    if (writeError != null) throw writeError!;
    lastMessage = 'Order marked for seller self-delivery.';
    dashboard = DispatchDashboard(
      summary: const DispatchSummary(readyOrders: 2, assignedOrders: 2),
      orders: dashboard.orders
          .map(
            (order) => order.orderId == orderId
                ? order.copyWith(
                    status: DispatchStatus.sellerSelfDelivery,
                    deliveryBoyId: () => null,
                    deliveryBoyName: () => null,
                  )
                : order,
          )
          .toList(),
    );
    return orderId;
  }
}

class DispatchTestServer {
  late HttpServer server;
  late String _orders;
  late String _dashboard;
  late String _availability;
  final requests = <({String method, Uri uri, String body})>[];
  int status = 200;
  Map<String, dynamic> response = {};
  Future<void> start() async {
    _orders = ApiRoutes.ordersApi;
    _dashboard = ApiRoutes.dispatchDashboardApi;
    _availability = ApiRoutes.riderAvailabilityApi;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiRoutes.ordersApi =
        'http://${server.address.host}:${server.port}/api/seller/orders';
    ApiRoutes.dispatchDashboardApi =
        '${ApiRoutes.ordersApi}/dispatch-dashboard';
    ApiRoutes.riderAvailabilityApi =
        '${ApiRoutes.ordersApi}/rider-availability';
    server.listen((request) async {
      expect(request.headers.value('authorization'), 'Bearer dispatch-test');
      expect(request.headers.value('accept'), 'application/json');
      requests.add((
        method: request.method,
        uri: request.uri,
        body: await utf8.decoder.bind(request).join(),
      ));
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    });
  }

  Future<void> close() async {
    ApiRoutes.ordersApi = _orders;
    ApiRoutes.dispatchDashboardApi = _dashboard;
    ApiRoutes.riderAvailabilityApi = _availability;
    await server.close(force: true);
  }
}
