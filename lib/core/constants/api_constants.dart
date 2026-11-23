class ApiConstants {
  static const String baseUrl = 'https://wger.de';
  static const String apiV2 = '$baseUrl/api/v2';

  // Supabase PostgreSQL & Auth Configuration
  static const String supabaseUrl = 'https://difljucolwkwqizpqoaa.supabase.co';
  static const String supabasePublishableKey =
      'sb_publishable_LPr6f8ykNxErN8JOnhhbLQ_prXht4VS';
  static const String supabaseAuthBase = '$supabaseUrl/auth/v1';
  static const String supabaseRestBase = '$supabaseUrl/rest/v1';

  // Default Login Credentials
  static const String defaultEmail = 'admin@gmail.com';
  static const String defaultPassword = 'password123';

  // Wger JWT Refresh Token (tersimpan di konfigurasi aplikasi)
  static const String wgerJwtToken =
      'eyJhbGciOiJSUzI1NiIsImtpZCI6IjVXVmlLSk10MVZHU3BXWE1BNkJEYnlpV2VkR1lvaVFHUFZ3UDFLMGtoUnciLCJ0eXAiOiJKV1QifQ.eyJpYXQiOjE3OTU0NDA2ODksImV4cCI6MTgwNTgwODY4OSwic2lkIjoiQnRqQTBJUWF5cHJXYXlWNUg2M252Rm9yenRBTVdHY1ZqeFlsOVF6RVhWZTgvTEZnNy84RUI2eCtZc1k3S3RoUCIsImp0aSI6ImJiYTQ3YTJmLTVmNmYtNGYzOS1hOTZmLTU0OWQxMWQxZjI3OCIsInRva2VuX3VzZSI6InJlZnJlc2giLCJzdWIiOiIyNjk3NDgifQ.DV-FsGzMVXu5k1_R2Rl0B-vGjajh6Abpd0uXmeG6cHkvTljMM0K8Q5G6b3Zh595PG8WPLgZK35LXz1Rxz6w8V9O8Uze7-ML-PTO67duNBKAdBt_K9OqSMdGcXmTUF4iswpPpAfJk9UxUkZtBn33RrqK6okONmR3Ad4Ue28tFoB8m7MgFhd6QJGqjWuUNZWD8EILr97HpTplsEgaQyhn4TJLbQdtIv8_bkQOpmDn2UX-FgRgxodbycoWpo2CYG7l72b3qyyNjKA_EzDS12Pzrryv61pP3-i8hkt-eahipYckHVCAglgtR_2SCah87WbaBXBNajEGg7Mvk1tLIjPimIg';

  // Auth endpoints (Allauth Headless + legacy fallback)
  static const String allauthLogin = '$baseUrl/_allauth/app/v1/auth/login';
  static const String allauthTokenRefresh =
      '$baseUrl/_allauth/app/v1/auth/token/refresh';
  static const String legacyTokenLogin = '$apiV2/token/';
  static const String legacyTokenRefresh = '$apiV2/token/refresh/';
  static const String userProfile = '$apiV2/userprofile/';

  // Public Exercise Catalog endpoints
  static const String exerciseInfo = '$apiV2/exerciseinfo/';
  static const String exerciseCategory = '$apiV2/exercisecategory/';
  static const String muscle = '$apiV2/muscle/';
  static const String equipment = '$apiV2/equipment/';

  // Personal Workout & Logging endpoints
  static const String routine = '$apiV2/routine/';
  static const String day = '$apiV2/day/';
  static const String slot = '$apiV2/slot/';
  static const String slotEntry = '$apiV2/slot-entry/';
  static const String workoutSession = '$apiV2/workoutsession/';
  static const String workoutLog = '$apiV2/workoutlog/';

  // SharedPreferences Keys
  static const String keyAuthSession = 'fitlog_auth_session';
  static const String keyWorkoutPlans = 'fitlog_workout_plans';
  static const String keyWorkoutLogs = 'fitlog_workout_logs';
  static const String keyActivePlanId = 'fitlog_active_plan_id';
  static const String keyThemeMode = 'fitlog_theme_mode';

  // Default English language ID in Wger
  static const int wgerEnglishLangId = 2;

  static const List<String> daysOfWeek = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
}
