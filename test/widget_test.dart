import 'package:flutter_test/flutter_test.dart';
import 'package:tmcebms/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(const TmcebmsApp(), isNotNull);
  });
}

