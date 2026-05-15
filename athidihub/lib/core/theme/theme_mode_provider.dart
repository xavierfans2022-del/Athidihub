import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Default: system theme (follows device). Falls back to light if system is light.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
