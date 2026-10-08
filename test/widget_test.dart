import 'package:flutter_test/flutter_test.dart';
import 'package:koala/game/game_data.dart';
import 'package:koala/game/game_screen.dart';
import 'package:koala/main.dart';

void main() {
  testWidgets('starts the Flame game screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KoalaGameApp());

    expect(find.byType(GameScreen), findsOneWidget);
    expect(levelDefinitions, hasLength(20));
    expect(skinNames, hasLength(10));
  });
}
