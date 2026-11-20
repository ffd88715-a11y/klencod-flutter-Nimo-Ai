import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkora_ai/app/router.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';
import 'package:talkora_ai/core/audio/sound_fx_service.dart';
import 'package:talkora_ai/core/knowledge/nimo_local_db_service.dart';
import 'package:talkora_ai/core/storage/app_state_provider.dart';

class TalkoraApp extends ConsumerWidget {
  const TalkoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    final router = ref.watch(appRouterProvider);
    // Warm up the 4,300+ offline database & click audio engine immediately on launch
    ref.watch(nimoLocalDbProvider);
    NimoSoundFx.enabled = profile.clickSoundEnabled;
    NimoSoundFx.warmUp();

    final isArabic = profile.uiLocale == 'ar';

    return MaterialApp.router(
      title: 'Nimo',
      debugShowCheckedModeBanner: false,
      theme: TalkoraTheme.light(isArabic: isArabic, accentKey: profile.accentColorKey),
      darkTheme: TalkoraTheme.dark(isArabic: isArabic, accentKey: profile.accentColorKey),
      themeMode: profile.themeMode,
      locale: Locale(profile.uiLocale),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: SelectionArea(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
