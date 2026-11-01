import 'package:flutter_test/flutter_test.dart';
import 'package:imkon_crm/main.dart';

void main() {
  test('SenovaCrmApp is the application root widget', () {
    const app = SenovaCrmApp();

    expect(app, isA<SenovaCrmApp>());
  });
}