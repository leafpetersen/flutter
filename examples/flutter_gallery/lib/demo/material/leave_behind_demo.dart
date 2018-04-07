// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart' show lowerBound;

import 'package:flutter/material.dart';

enum LeaveBehindDemoAction { reset, horizontalSwipe, leftSwipe, rightSwipe }

class LeaveBehindItem implements Comparable<LeaveBehindItem> {
  LeaveBehindItem({this.index, this.name, this.subject, this.body});

  LeaveBehindItem.from(LeaveBehindItem item)
      : index = item.index,
        name = item.name,
        subject = item.subject,
        body = item.body;

  final int index;
  final String name;
  final String subject;
  final String body;

  @override
  int compareTo(LeaveBehindItem other) => index.compareTo(other.index);
}

class LeaveBehindDemo extends StatefulWidget {
  const LeaveBehindDemo({Key key}) : super(key: key);

  static const String routeName = '/material/leave-behind';

  @override
  LeaveBehindDemoState createState() => LeaveBehindDemoState();
}

class LeaveBehindDemoState extends State<LeaveBehindDemo> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();
  DismissDirection _dismissDirection = DismissDirection.horizontal;
  List<LeaveBehindItem> leaveBehindItems;

  void initListItems() {
    leaveBehindItems = List<LeaveBehindItem>.generate(16, (int index) {
      return LeaveBehindItem(
          index: index,
          name: 'Item $index Sender',
          subject: 'Subject: $index',
          body: "[$index] first line of the message's body...");
    });
  }

  @override
  void initState() {
    super.initState();
    initListItems();
  }

  void handleDemoAction(LeaveBehindDemoAction action) {
    setState(() {
      switch (action) {
        case LeaveBehindDemoAction.reset:
          initListItems();
          break;
        case LeaveBehindDemoAction.horizontalSwipe:
          _dismissDirection = DismissDirection.horizontal;
          break;
        case LeaveBehindDemoAction.leftSwipe:
          _dismissDirection = DismissDirection.endToStart;
          break;
        case LeaveBehindDemoAction.rightSwipe:
          _dismissDirection = DismissDirection.startToEnd;
          break;
      }
    });
  }

  void handleUndo(LeaveBehindItem item) {
    final int insertionIndex = lowerBound(leaveBehindItems, item);
    setState(() {
      leaveBehindItems.insert(insertionIndex, item);
    });
  }

  Widget buildItem(LeaveBehindItem item) {
    final ThemeData theme = Theme.of(context);
    return Dismissible(
        key: ObjectKey(item),
        direction: _dismissDirection,
        onDismissed: (DismissDirection direction) {
          setState(() {
            leaveBehindItems.remove(item);
          });
          final String action = (direction == DismissDirection.endToStart)
              ? 'archived'
              : 'deleted';
          _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('You $action item ${item.index}'),
              action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () {
                    handleUndo(item);
                  })));
        },
        background: Container(
            color: theme.primaryColor,
            child: const ListTile(
                leading: Icon(Icons.delete, color: Colors.white, size: 36.0))),
        secondaryBackground: Container(
            color: theme.primaryColor,
            child: const ListTile(
                trailing:
                    Icon(Icons.archive, color: Colors.white, size: 36.0))),
        child: Container(
            decoration: BoxDecoration(
                color: theme.canvasColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: ListTile(
                title: Text(item.name),
                subtitle: Text('${item.subject}\n${item.body}'),
                isThreeLine: true)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Swipe to dismiss'), actions: <Widget>[
        PopupMenuButton<LeaveBehindDemoAction>(
            onSelected: handleDemoAction,
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<LeaveBehindDemoAction>>[
                  const PopupMenuItem<LeaveBehindDemoAction>(
                      value: LeaveBehindDemoAction.reset,
                      child: Text('Reset the list')),
                  const PopupMenuDivider(), // ignore: list_element_type_not_assignable, https://github.com/flutter/flutter/issues/5771
                  CheckedPopupMenuItem<LeaveBehindDemoAction>(
                      value: LeaveBehindDemoAction.horizontalSwipe,
                      checked: _dismissDirection == DismissDirection.horizontal,
                      child: const Text('Horizontal swipe')),
                  CheckedPopupMenuItem<LeaveBehindDemoAction>(
                      value: LeaveBehindDemoAction.leftSwipe,
                      checked: _dismissDirection == DismissDirection.endToStart,
                      child: const Text('Only swipe left')),
                  CheckedPopupMenuItem<LeaveBehindDemoAction>(
                      value: LeaveBehindDemoAction.rightSwipe,
                      checked: _dismissDirection == DismissDirection.startToEnd,
                      child: const Text('Only swipe right'))
                ])
      ]),
      body: leaveBehindItems.isEmpty
          ? Center(
              child: RaisedButton(
                onPressed: () => handleDemoAction(LeaveBehindDemoAction.reset),
                child: const Text('Reset the list'),
              ),
            )
          : ListView(children: leaveBehindItems.map(buildItem).toList()),
    );
  }
}
