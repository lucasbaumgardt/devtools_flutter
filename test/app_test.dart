import 'package:devtools_flutter/app.dart';
import 'package:devtools_flutter/tools/tool_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Finder field(String label) => find.widgetWithText(TextField, label);

String textOf(WidgetTester tester, String label) =>
    tester.widget<TextField>(field(label)).controller!.text;

void main() {
  group('tool search', () {
    List<String> names(String query) =>
        searchTools(query).map((tool) => tool.shortName).toList();

    test('ignores case and accents; every word must match', () {
      expect(names('formatar'), ['JSON']);
      expect(names('guid'), ['UUID']);
      expect(names('aleatorios'), ['UUID']);
      expect(names('JSON'), ['JSON', 'JWT']); // JSON Web Token
      expect(names('json uuid'), isEmpty);
      expect(names('  '), hasLength(devTools.length));
    });
  });

  testWidgets('formats JSON while typing and explains errors', (tester) async {
    await tester.pumpWidget(const DevToolsApp());
    expect(find.text('JSON Formatter'), findsOneWidget);

    await tester.enterText(field('Entrada'), '{"name":"Lucas","age":30}');
    await tester.pump();
    expect(
      textOf(tester, 'Resultado'),
      '{\n  "name": "Lucas",\n  "age": 30\n}',
    );
    expect(find.text('JSON válido'), findsOneWidget);

    await tester.enterText(field('Entrada'), '{\n  "a": 1,\n}');
    await tester.pump();
    expect(find.text('JSON inválido — linha 2, coluna 9'), findsOneWidget);
    expect(find.text('Vírgula sobrando antes de "}".'), findsOneWidget);
    expect(textOf(tester, 'Resultado'), isEmpty);
  });

  testWidgets('copies the result to the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(const DevToolsApp());
    await tester.enterText(field('Entrada'), '[1,2]');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Copiar'));
    await tester.pump();

    expect(copied, '[\n  1,\n  2\n]');
    expect(find.text('Copiado para a área de transferência'), findsOneWidget);
  });

  testWidgets('narrow screens switch tools through the drawer', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DevToolsApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationDrawer),
        matching: find.text('UUID'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.text('UUID Generator'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^[0-9a-f]{8}-')), findsOneWidget);
  });

  testWidgets('wide screens show the sidebar', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DevToolsApp());
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);

    await tester.tap(find.text('JWT'));
    await tester.pumpAndSettle();
    expect(find.text('JWT Decoder'), findsOneWidget);
    expect(
      find.textContaining('a assinatura não é verificada'),
      findsOneWidget,
    );
  });
}
