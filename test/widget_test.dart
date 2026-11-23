import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlog_pro/main.dart';

void main() {
  testWidgets('FitLog Pro renders email/password login and enters app', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(FitLogProApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('FitLog Pro'), findsWidgets);
    expect(find.text('Masuk ke Akun'), findsOneWidget);

    await tester.tap(find.text('Pakai akun default'));
    await tester.pumpAndSettle();

    final loginBtn = find.text('Masuk ke Gym Mode');
    await tester.ensureVisible(loginBtn);
    await tester.pumpAndSettle();
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('Admin FitLog'), findsWidgets);
  });
}
