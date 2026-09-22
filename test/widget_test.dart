import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

void main() {
  group('ApiException', () {
    test('toString returns the plain backend message', () {
      expect(ApiException('Invalid credentials').toString(),
          'Invalid credentials');
    });

    test('rethrown errors are not double-prefixed', () {
      Object? caught;
      try {
        try {
          throw ApiException('Store not found');
        } catch (e) {
          rethrow;
        }
      } catch (e) {
        caught = e;
      }
      expect(caught.toString(), 'Store not found');
    });

    test('null message becomes empty string', () {
      expect(ApiException(null).toString(), '');
    });
  });
}
