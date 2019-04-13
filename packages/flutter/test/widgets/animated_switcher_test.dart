// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimatedSwitcher fades in a new child.', (WidgetTester tester) async {
    final UniqueKey containerOne = UniqueKey();
    final UniqueKey containerTwo = UniqueKey();
    final UniqueKey containerThree = UniqueKey();
    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: containerOne, color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: containerTwo, color: const Color(0xff000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FadeTransition), findsNWidgets(2));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: containerThree, color: const Color(0xffff0000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));
    transition = tester.widget(find.byType(FadeTransition).at(0));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(1));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(2));
    expect(transition.opacity.value, closeTo(0.1, 0.01));
    await tester.pumpAndSettle();
  });

  testWidgets('AnimatedSwitcher can handle back-to-back changes.', (WidgetTester tester) async {
    final UniqueKey container1 = UniqueKey();
    final UniqueKey container2 = UniqueKey();
    final UniqueKey container3 = UniqueKey();
    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: container1),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );
    expect(find.byKey(container1), findsOneWidget);
    expect(find.byKey(container2), findsNothing);
    expect(find.byKey(container3), findsNothing);

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: container2),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );
    expect(find.byKey(container1), findsOneWidget);
    expect(find.byKey(container2), findsOneWidget);
    expect(find.byKey(container3), findsNothing);

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: container3),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );
    expect(find.byKey(container1), findsOneWidget);
    expect(find.byKey(container2), findsNothing);
    expect(find.byKey(container3), findsOneWidget);
  });

  testWidgets("AnimatedSwitcher doesn't transition in a new child of the same type.", (WidgetTester tester) async {
    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(color: const Color(0xff000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FadeTransition), findsOneWidget);
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));
    await tester.pumpAndSettle();
  });

  testWidgets('AnimatedSwitcher handles null children.', (WidgetTester tester) async {
    await tester.pumpWidget(
      const AnimatedSwitcher(
        duration: Duration(milliseconds: 100),
        child: null,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsNothing);

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(color: const Color(0xff000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      const AnimatedSwitcher(
        duration: Duration(milliseconds: 100),
        child: null,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));

    await tester.pumpWidget(
      const AnimatedSwitcher(
        duration: Duration(milliseconds: 100),
        child: null,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.0));

    await tester.pumpAndSettle();
  });

  testWidgets("AnimatedSwitcher doesn't start any animations after dispose.", (WidgetTester tester) async {
    await tester.pumpWidget(AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: Container(color: const Color(0xff000000)),
      switchInCurve: Curves.linear,
    ));
    await tester.pump(const Duration(milliseconds: 50));

    // Change the widget tree in the middle of the animation.
    await tester.pumpWidget(Container(color: const Color(0xffff0000)));
    expect(await tester.pumpAndSettle(const Duration(milliseconds: 100)), equals(1));
  });

  testWidgets('AnimatedSwitcher uses custom layout.', (WidgetTester tester) async {
    Widget newLayoutBuilder(Widget currentChild, List<Widget> previousChildren) {
      return Column(
        children: previousChildren + <Widget>[currentChild],
      );
    }

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        layoutBuilder: newLayoutBuilder,
      ),
    );

    expect(find.byType(Column), findsOneWidget);
  });

  testWidgets('AnimatedSwitcher uses custom transitions.', (WidgetTester tester) async {
    final List<Widget> foundChildren = <Widget>[];
    Widget newLayoutBuilder(Widget currentChild, List<Widget> previousChildren) {
      foundChildren.clear();
      if (currentChild != null) {
        foundChildren.add(currentChild);
      }
      foundChildren.addAll(previousChildren);
      return Column(
        children: foundChildren,
      );
    }

    Widget newTransitionBuilder(Widget child, Animation<double> animation) {
      return SizeTransition(
        sizeFactor: animation,
        child: child,
      );
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: Container(color: const Color(0x00000000)),
          switchInCurve: Curves.linear,
          layoutBuilder: newLayoutBuilder,
          transitionBuilder: newTransitionBuilder,
        ),
      ),
    );

    expect(find.byType(Column), findsOneWidget);
    for (Widget child in foundChildren) {
      expect(child, isInstanceOf<KeyedSubtree>());
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: null,
          switchInCurve: Curves.linear,
          layoutBuilder: newLayoutBuilder,
          transitionBuilder: newTransitionBuilder,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    for (Widget child in foundChildren) {
      expect(child, isInstanceOf<KeyedSubtree>());
      expect(
        find.descendant(of: find.byWidget(child), matching: find.byType(SizeTransition)),
        findsOneWidget,
      );
    }
  });

  testWidgets("AnimatedSwitcher doesn't reset state of the children in transitions.", (WidgetTester tester) async {
    final UniqueKey statefulOne = UniqueKey();
    final UniqueKey statefulTwo = UniqueKey();
    final UniqueKey statefulThree = UniqueKey();

    StatefulTestState.generation = 0;

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: StatefulTest(key: statefulOne),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));
    expect(StatefulTestState.generation, equals(1));

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: StatefulTest(key: statefulTwo),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FadeTransition), findsNWidgets(2));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));
    expect(StatefulTestState.generation, equals(2));

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: StatefulTest(key: statefulThree),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));
    expect(StatefulTestState.generation, equals(3));
    transition = tester.widget(find.byType(FadeTransition).at(0));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(1));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(2));
    expect(transition.opacity.value, closeTo(0.1, 0.01));
    await tester.pumpAndSettle();
    expect(StatefulTestState.generation, equals(3));
  });

  testWidgets('AnimatedSwitcher updates widgets without animating if they are isomorphic.', (WidgetTester tester) async {
    Future<void> pumpChild(Widget child) async {
      return tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            child: child,
            switchInCurve: Curves.linear,
            switchOutCurve: Curves.linear,
          ),
        ),
      );
    }

    await pumpChild(const Text('1'));
    await tester.pump(const Duration(milliseconds: 10));
    FadeTransition transition = tester.widget(find.byType(FadeTransition).first);
    expect(transition.opacity.value, equals(1.0));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    await pumpChild(const Text('2'));
    transition = tester.widget(find.byType(FadeTransition).first);
    await tester.pump(const Duration(milliseconds: 20));
    expect(transition.opacity.value, equals(1.0));
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('AnimatedSwitcher updates previous child transitions if the transitionBuilder changes.', (WidgetTester tester) async {
    final UniqueKey containerOne = UniqueKey();
    final UniqueKey containerTwo = UniqueKey();
    final UniqueKey containerThree = UniqueKey();

    final List<Widget> foundChildren = <Widget>[];
    Widget newLayoutBuilder(Widget currentChild, List<Widget> previousChildren) {
      foundChildren.clear();
      if (currentChild != null) {
        foundChildren.add(currentChild);
      }
      foundChildren.addAll(previousChildren);
      return Column(
        children: foundChildren,
      );
    }

    // Insert three unique children so that we have some previous children.
    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: containerOne, color: const Color(0xFFFF0000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        layoutBuilder: newLayoutBuilder,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: containerTwo, color: const Color(0xFF00FF00)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        layoutBuilder: newLayoutBuilder,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));

    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(key: containerThree, color: const Color(0xFF0000FF)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        layoutBuilder: newLayoutBuilder,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));

    expect(foundChildren.length, equals(3));
    for (Widget child in foundChildren) {
      expect(child, isInstanceOf<KeyedSubtree>());
      expect(
        find.descendant(of: find.byWidget(child), matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
    }

    Widget newTransitionBuilder(Widget child, Animation<double> animation) {
      return ScaleTransition(
        scale: animation,
        child: child,
      );
    }

    // Now set a new transition builder and make sure all the previous
    // transitions are replaced.
    await tester.pumpWidget(
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        layoutBuilder: newLayoutBuilder,
        transitionBuilder: newTransitionBuilder,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));

    expect(foundChildren.length, equals(3));
    for (Widget child in foundChildren) {
      expect(child, isInstanceOf<KeyedSubtree>());
      expect(
        find.descendant(of: find.byWidget(child), matching: find.byType(ScaleTransition)),
        findsOneWidget,
      );
    }
  });
}

class StatefulTest extends StatefulWidget {
  const StatefulTest({[Key key]}) : super(key: key);

  @override
  StatefulTestState createState() => StatefulTestState();
}

class StatefulTestState extends State<StatefulTest> {
  StatefulTestState();
  static int generation = 0;

  @override
  void initState() {
    super.initState();
    generation++;
  }

  @override
  Widget build(BuildContext context) => Container();
}
