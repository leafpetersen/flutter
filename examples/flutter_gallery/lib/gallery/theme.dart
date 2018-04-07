// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class GalleryTheme {
  const GalleryTheme({this.name, this.icon, this.theme});
  final String name;
  final IconData icon;
  final ThemeData theme;
}

const int _kPurplePrimaryValue = 0xFF6200EE;
const MaterialColor _kPurpleSwatch =
    MaterialColor(_kPurplePrimaryValue, <int, Color>{
  50: Color(0xFFF2E7FE),
  100: Color(0xFFD7B7FD),
  200: Color(0xFFBB86FC),
  300: Color(0xFF9E55FC),
  400: Color(0xFF7F22FD),
  500: Color(_kPurplePrimaryValue),
  700: Color(0xFF3700B3),
  800: Color(0xFF270096),
  900: Color(0xFF190078),
});

final List<GalleryTheme> kAllGalleryThemes = <GalleryTheme>[
  GalleryTheme(
    name: 'Light',
    icon: Icons.brightness_5,
    theme: ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
    ),
  ),
  GalleryTheme(
    name: 'Dark',
    icon: Icons.brightness_7,
    theme: ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
    ),
  ),
  GalleryTheme(
    name: 'Purple',
    icon: Icons.brightness_6,
    theme: ThemeData(
      brightness: Brightness.light,
      primarySwatch: _kPurpleSwatch,
      buttonColor: _kPurpleSwatch[500],
      splashColor: Colors.white24,
      splashFactory: InkRipple.splashFactory,
      errorColor: const Color(0xFFFF1744),
      buttonTheme: const ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
      ),
    ),
  ),
];
