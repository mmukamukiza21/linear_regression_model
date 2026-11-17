
import 'package:flutter_test/flutter_test.dart';
import 'package:retail_revenue_app/main.dart';

void main() {
  testWidgets('Revenue prediction app displays correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RevenuePredictionApp());

    expect(find.text('Retail Revenue Predictor'), findsOneWidget);
    expect(find.text('Daily Revenue Prediction'), findsOneWidget);
    expect(find.text('Predict Revenue'), findsOneWidget);
  });
}
