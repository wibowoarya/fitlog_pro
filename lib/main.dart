import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_storage_service.dart';
import 'data/datasources/supabase_service.dart';
import 'data/datasources/wger_api_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/exercise_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_shell_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/rest_timer_provider.dart';
import 'providers/workout_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(FitLogProApp(prefs: prefs));
}

class FitLogProApp extends StatelessWidget {
  final SharedPreferences prefs;

  const FitLogProApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorageService(prefs);
    final apiService = WgerApiService();
    final supabaseService = SupabaseService();

    final authRepo = AuthRepository(
      apiService: apiService,
      supabaseService: supabaseService,
      storage: storage,
    );
    final exerciseRepo = ExerciseRepository(apiService: apiService);
    final workoutRepo = WorkoutRepository(
      storage: storage,
      apiService: apiService,
      supabaseService: supabaseService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: authRepo,
            storage: storage,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ExerciseProvider(repository: exerciseRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => WorkoutProvider(repository: workoutRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => RestTimerProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'FitLog Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: auth.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: auth.isAuthenticated
                  ? const MainShellScreen(key: ValueKey('main'))
                  : const LoginScreen(key: ValueKey('login')),
            ),
          );
        },
      ),
    );
  }
}
