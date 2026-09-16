import 'package:flutter_test/flutter_test.dart';
import 'package:qify_authenticator/app/app.dart';

void main() {
  testWidgets('Qify Authenticator starts', (tester) async {
    await tester.pumpWidget(
      const QifyAuthenticatorApp(),
    );

    await tester.pump();

    expect(
      find.text('Qify Authenticator'),
      findsOneWidget,
    );
  });
}