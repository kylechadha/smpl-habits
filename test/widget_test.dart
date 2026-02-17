// Basic widget tests for smpl_tracker

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smpl_tracker/screens/sign_in_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('SignInScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );

    // Verify the app title is shown
    expect(find.text('smpl'), findsOneWidget);

    // Verify the tagline is shown
    expect(find.text('Simple habit tracking'), findsOneWidget);

    // Verify the sign in button is present
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
