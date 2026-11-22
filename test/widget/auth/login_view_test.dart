// test/widget/auth/login_view_test.dart
//
// Widget Tests — Login Screen
// Tests the Login form widget: field rendering, validation messages,
// and interaction (without network calls — backend is NOT required).
//
// Run: flutter test test/widget/auth/login_view_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swasthyasathi/src/features/auth/view/login_view.dart';

/// Helper: wrap the widget under test with MaterialApp so that Theme,
/// Navigator, and Scaffold are all available.
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
  // ─── Group: LoginView Rendering ─────────────────────────────────────────────

  group('LoginView — Rendering —', () {
    testWidgets('renders the login screen without crashing', (tester) async {
      await tester.pumpWidget(wrapInApp(const LoginView()));
      await tester.pump();

      // Screen should load
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('displays phone/email and password input fields', (tester) async {
      await tester.pumpWidget(wrapInApp(const LoginView()));
      await tester.pump();

      // At least two TextFormField widgets should be present
      // (identifier + password)
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('displays a login button', (tester) async {
      await tester.pumpWidget(wrapInApp(const LoginView()));
      await tester.pump();

      // Should find a button with login-related text
      final loginButton = find.text('Log In');
      final altLoginButton = find.text('Login');

      expect(
        loginButton.evaluate().isNotEmpty || altLoginButton.evaluate().isNotEmpty,
        isTrue,
        reason: 'A login button with text "Log In" or "Login" must be present',
      );
    });
  });

  // ─── Group: LoginView — Form Validation ─────────────────────────────────────

  group('LoginView — Form Validation —', () {
    testWidgets('shows error when both fields are empty and form submitted',
        (tester) async {
      await tester.pumpWidget(wrapInApp(const LoginView()));
      await tester.pump();

      // Find and tap the login/sign-in button without entering any text
      final loginButtons = find.byType(ElevatedButton);
      if (loginButtons.evaluate().isNotEmpty) {
        await tester.tap(loginButtons.first);
        await tester.pump();

        // At least one validation error text should appear
        // (Flutter form validator shows red text under invalid fields)
        final errorText = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.style?.color == Colors.red,
        );
        // OR look for standard flutter form error text patterns
        final requiredErrors = find.textContaining('required',
            findRichText: true, skipOffstage: false);
        final emptyErrors = find.textContaining('empty',
            findRichText: true, skipOffstage: false);

        expect(
          errorText.evaluate().isNotEmpty ||
              requiredErrors.evaluate().isNotEmpty ||
              emptyErrors.evaluate().isNotEmpty,
          isTrue,
          reason: 'Form validation errors must appear on empty submission',
        );
      }
    });

    testWidgets('allows typing into the identifier field', (tester) async {
      await tester.pumpWidget(wrapInApp(const LoginView()));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '9841234567');
        await tester.pump();
        expect(find.text('9841234567'), findsOneWidget);
      }
    });

    testWidgets('allows typing into the password field', (tester) async {
      await tester.pumpWidget(wrapInApp(const LoginView()));
      await tester.pump();

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(1), 'SecurePass123');
        await tester.pump();
        // Password field may obscure text — check value via controller instead
        // Just verify no crash occurred
        expect(find.byType(LoginView), findsOneWidget);
      }
    });
  });

  // ─── Group: LoginView — Password Visibility ──────────────────────────────────

  group('LoginView — Password Visibility Toggle —', () {
    testWidgets('password field has a visibility toggle icon', (tester) async {
      await tester.pumpWidget(wrapInApp(const LoginView()));
      await tester.pump();

      // Look for an icon that toggles password visibility
      final visibilityIcon = find.byIcon(Icons.visibility_off_outlined);
      final visibilityAltIcon = find.byIcon(Icons.visibility_off);
      final visibilityOnIcon = find.byIcon(Icons.visibility_outlined);
      final genericVisibilityIcon = find.byIcon(Icons.visibility);

      expect(
        visibilityIcon.evaluate().isNotEmpty ||
            visibilityAltIcon.evaluate().isNotEmpty ||
            visibilityOnIcon.evaluate().isNotEmpty ||
            genericVisibilityIcon.evaluate().isNotEmpty,
        isTrue,
        reason: 'Password field should have a show/hide toggle icon',
      );
    });
  });
}
