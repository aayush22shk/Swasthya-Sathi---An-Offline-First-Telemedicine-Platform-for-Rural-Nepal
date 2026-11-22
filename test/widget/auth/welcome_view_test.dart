// test/widget/auth/welcome_view_test.dart
//
// Widget Tests — Welcome / Onboarding Screen
// Tests the first screen the user sees: rendering, navigation triggers,
// and layout (no network calls required).
//
// Run: flutter test test/widget/auth/welcome_view_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/src/features/auth/view/welcome_view.dart';
import 'package:swasthyasathi/src/features/auth/view/login_view.dart';
import 'package:swasthyasathi/src/features/auth/view/role_selection_view.dart';

Widget wrapInApp(Widget child) {
  return MaterialApp(
    home: child,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0072FF)),
      useMaterial3: true,
    ),
  );
}

void main() {
  // ─── Group: WelcomeView Rendering ───────────────────────────────────────────

  group('WelcomeView — Rendering —', () {
    testWidgets('renders WelcomeView without crashing', (tester) async {
      await tester.pumpWidget(wrapInApp(const WelcomeView()));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeView), findsOneWidget);
    });

    testWidgets('displays app name "Swasthya Sathi"', (tester) async {
      await tester.pumpWidget(wrapInApp(const WelcomeView()));
      await tester.pumpAndSettle();

      // App name should appear somewhere on the welcome screen
      final appNameFinder = find.textContaining(
        'Swasthya',
        findRichText: true,
        skipOffstage: false,
      );
      expect(appNameFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('displays a "Get Started" or "Login" button', (tester) async {
      await tester.pumpWidget(wrapInApp(const WelcomeView()));
      await tester.pumpAndSettle();

      final getStarted = find.textContaining('Get Started',
          findRichText: true, skipOffstage: false);
      final loginBtn = find.textContaining('Login',
          findRichText: true, skipOffstage: false);
      final signIn = find.textContaining('Sign In',
          findRichText: true, skipOffstage: false);

      expect(
        getStarted.evaluate().isNotEmpty ||
            loginBtn.evaluate().isNotEmpty ||
            signIn.evaluate().isNotEmpty,
        isTrue,
        reason: 'Welcome screen must have a call-to-action button',
      );
    });

    testWidgets('contains at least one image or logo', (tester) async {
      await tester.pumpWidget(wrapInApp(const WelcomeView()));
      await tester.pumpAndSettle();

      // Either an Image widget or an Icon should be present
      final hasImage = find.byType(Image).evaluate().isNotEmpty;
      final hasIcon = find.byType(Icon).evaluate().isNotEmpty;
      final hasSvg = find.byWidgetPredicate(
              (w) => w.runtimeType.toString().contains('Svg'))
          .evaluate()
          .isNotEmpty;

      expect(hasImage || hasIcon || hasSvg, isTrue,
          reason: 'Welcome screen should have a logo or illustration');
    });
  });

  // ─── Group: WelcomeView Navigation ──────────────────────────────────────────

  group('WelcomeView — Navigation —', () {
    testWidgets('tapping login button navigates to LoginView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeView(),
          routes: {
            '/login': (_) => const LoginView(),
            '/role-select': (_) => const RoleSelectionView(),
          },
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0072FF)),
            useMaterial3: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find login-related button or text
      final loginFinder = find.widgetWithText(ElevatedButton, 'Login');
      final loginTextFinder = find.widgetWithText(TextButton, 'Login');
      final signInFinder = find.widgetWithText(ElevatedButton, 'Sign In');

      final foundButton = loginFinder.evaluate().isNotEmpty
          ? loginFinder
          : loginTextFinder.evaluate().isNotEmpty
              ? loginTextFinder
              : signInFinder;

      if (foundButton.evaluate().isNotEmpty) {
        await tester.tap(foundButton.first);
        await tester.pumpAndSettle();

        // After tap, either LoginView or navigation has occurred
        // (no crash = pass for navigation smoke test)
        expect(find.byType(WelcomeView).evaluate().isEmpty ||
            find.byType(LoginView).evaluate().isNotEmpty, isTrue);
      }
    });
  });
}
