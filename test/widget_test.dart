import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkora_ai/app/app.dart';
import 'package:talkora_ai/core/ai/ai_provider_models.dart';
import 'package:talkora_ai/core/widgets/talkora_waveform.dart';

void main() {
  testWidgets('LISORA AI v3.0 boots splash screen cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TalkoraApp()));
    expect(find.text('TALKORA AI'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
  });

  testWidgets('TalkoraWaveform renders real amplitude samples without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TalkoraWaveform(amplitudeHistory: [0.1, 0.4, 0.8, 0.3, 0.2]),
        ),
      ),
    );
    expect(find.byType(TalkoraWaveform), findsOneWidget);
  });

  test('AiProviderCatalog contains all 12 providers including Free Cloud AI & custom endpoint', () {
    expect(AiProviderCatalog.all.length, 12);
    expect(AiProviderCatalog.byId('pollinations').requiresApiKey, false);
    expect(AiProviderCatalog.byId('openai').name, 'OpenAI (GPT)');
    expect(AiProviderCatalog.byId('gemini').wireFormat, AiWireFormat.googleGemini);
    expect(AiProviderCatalog.byId('claude').wireFormat, AiWireFormat.anthropicClaude);
    expect(AiProviderCatalog.byId('custom').id, 'custom');
  });
}
