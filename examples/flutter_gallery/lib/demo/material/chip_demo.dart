// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ChipDemo extends StatefulWidget {
  static const String routeName = '/material/chip';

  @override
  _ChipDemoState createState() => _ChipDemoState();
}

class _ChipDemoState extends State<ChipDemo> {
  bool _showBananas = true;

  void _deleteBananas() {
    setState(() {
      _showBananas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      const Chip(label: Text('Apple')),
      const Chip(
        avatar: CircleAvatar(child: Text('B')),
        label: Text('Blueberry'),
      ),
    ];

    if (_showBananas) {
      chips.add(Chip(label: const Text('Bananas'), onDeleted: _deleteBananas));
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Chips')),
        body: ListView(
            children: chips.map((Widget chip) {
          return Container(height: 100.0, child: Center(child: chip));
        }).toList()));
  }
}
