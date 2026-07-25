import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'state/app_controller.dart';
import 'ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(RavandApp(preferences: preferences));
}

class RavandApp extends StatefulWidget {
  const RavandApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<RavandApp> createState() => _RavandAppState();
}

class _RavandAppState extends State<RavandApp> {
  late final AppController controller = AppController(
    preferences: widget.preferences,
  );

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رَوَند | تحلیل بازار خودرو',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: AppShell(controller: controller),
    );
  }
}
