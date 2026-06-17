import 'package:flutter/material.dart';

Route<T> slideInRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => SlideTransition(
    position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: a, child: child),
  ),
  transitionDuration: const Duration(milliseconds: 280),
);

Route<T> fadeInRoute<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  transitionDuration: const Duration(milliseconds: 200),
);