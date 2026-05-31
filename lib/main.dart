import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/supabase_client.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru', null);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://osedmlfkdrihkvxaaxcn.supabase.co',
    anonKey: 'sb_publishable_H12QQJgtOV0ROzG7wbS0Iw_83DQ8JGO',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Проверяем есть ли активная сессия
    final session = supabase.auth.currentSession;

    return MaterialApp(
      title: 'Столовая',
      theme: AppTheme.dark,
      // Если сессия есть — сразу на главный экран, нет — на логин
      home: session != null ? const HomeScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
