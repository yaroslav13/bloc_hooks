import 'package:bloc_hooks/bloc_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../utils.dart';

/// Convenience wrapper: MaterialApp →
/// HookBuilder → useBlocScope → Builder → child.
final class TestApp extends StatelessWidget {
  const TestApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HookBuilder(
        builder: (_) {
          useBlocScope(appFactory);

          return Builder(builder: (_) => child);
        },
      ),
    );
  }
}
