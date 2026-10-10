import 'package:flutter_test/flutter_test.dart';
import 'package:secure_app/main.dart';

void main() {
  testWidgets('Secure Notes app opens', (tester) async {
    await tester.pumpWidget(const SecureNotesApp());

    expect(find.text('Secure Notes'), findsOneWidget);
    expect(find.text('Add Note'), findsOneWidget);
  });
}
