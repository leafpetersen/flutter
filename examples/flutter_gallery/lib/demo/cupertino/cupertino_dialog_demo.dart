// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoDialogDemo extends StatefulWidget {
  static const String routeName = '/cupertino/dialog';

  @override
  _CupertinoDialogDemoState createState() => _CupertinoDialogDemoState();
}

class _CupertinoDialogDemoState extends State<CupertinoDialogDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text('You selected: $value')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Cupertino Dialogs'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 72.0),
        children: <Widget>[
          CupertinoButton(
            child: const Text('Alert'),
            color: CupertinoColors.activeBlue,
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: CupertinoAlertDialog(
                    content: const Text('Discard draft?'),
                    actions: <Widget>[
                      CupertinoDialogAction(
                          child: const Text('Discard'),
                          isDestructiveAction: true,
                          onPressed: () {
                            Navigator.pop(context, 'Discard');
                          }),
                      CupertinoDialogAction(
                          child: const Text('Cancel'),
                          isDefaultAction: true,
                          onPressed: () {
                            Navigator.pop(context, 'Cancel');
                          }),
                    ]),
              );
            },
          ),
          const Padding(padding: EdgeInsets.all(8.0)),
          CupertinoButton(
            child: const Text('Alert with Title'),
            color: CupertinoColors.activeBlue,
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: CupertinoAlertDialog(
                    title: const Text(
                        'Allow "Maps" to access your location while you use the app?'),
                    content: const Text(
                        'Your current location will be displayed on the map and used for directions, '
                        'nearby search results, and estimated travel times.'),
                    actions: <Widget>[
                      CupertinoDialogAction(
                          child: const Text('Don\'t Allow'),
                          onPressed: () {
                            Navigator.pop(context, 'Disallow');
                          }),
                      CupertinoDialogAction(
                          child: const Text('Allow'),
                          onPressed: () {
                            Navigator.pop(context, 'Allow');
                          }),
                    ]),
              );
            },
          ),
        ],
      ),
    );
  }
}
