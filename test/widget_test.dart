import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chata/theme.dart';
import 'package:smart_chata/widgets/hearth_ui.dart';

void main() {
  testWidgets('Hearth basic UI widgets render properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              HearthProgressBar(value: 0.5),
              SectionHeader(title: 'Test Section', sub: 'Sub title'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Test Section'), findsOneWidget);
    expect(find.text('SUB TITLE'), findsOneWidget);
  });
}
