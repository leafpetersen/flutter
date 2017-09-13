// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'feedback.dart';
import 'theme.dart';
import 'theme_data.dart';

const Duration _kFadeDuration = const Duration(milliseconds: 200);
const Duration _kShowDuration = const Duration(milliseconds: 1500);

/// A quick start tooltip.
///
/// See also:
///
///  * <https://material.google.com/components/tooltips.html>
class QuickStartTooltip extends StatefulWidget {
  /// Creates a tooltip.
  ///
  /// The [message] argument must not be null.
  const QuickStartTooltip({
    Key key,
    @required this.message,
    this.padding: const EdgeInsets.all(32.0),
    @required this.child,
  }) : assert(message != null),
        assert(padding != null),
        assert(child != null),
        super(key: key);

  /// The text to display in the tooltip.
  final String message;

  /// The amount of space by which to inset the child.
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry padding;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _QuickStartTooltipState createState() => new _QuickStartTooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new StringProperty('message', message, showName: false));
  }
}

class _QuickStartTooltipState extends State<QuickStartTooltip> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: _kFadeDuration, vsync: this)
      ..addStatusListener(_handleStatusChanged);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed)
      _removeEntry();
  }

  /// Shows the tooltip if it is not already visible.
  ///
  /// Returns `false` when the tooltip was already visible.
  bool ensureTooltipVisible() {
    if (_entry != null) {
      _controller.forward();
      return false; // Already visible.
    }
    final RenderBox box = context.findRenderObject();
    final Matrix4 transform = box.getTransformTo(null);
    // final Offset target = box.localToGlobal(box.size.center(Offset.zero));
    // We create this widget outside of the overlay entry's builder to prevent
    // updated values from happening to leak into the overlay when the overlay
    // rebuilds.
    final Rect targetRect = MatrixUtils.transformRect(
        transform, box.semanticBounds).inflate(16.0);
    final Widget overlay = new _QuickStartTooltipOverlay(
        message: widget.message,
        padding: widget.padding,
        width: 200.0,
        height: 200.0,
        animation: new CurvedAnimation(
            parent: _controller,
            curve: Curves.fastOutSlowIn
        ),
        targetRect: targetRect,
    );
    _entry = new OverlayEntry(builder: (BuildContext context) => overlay);
    Overlay.of(context, debugRequiredFor: widget).insert(_entry);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    _controller.forward();
    return true;
  }

  void _removeEntry() {
    assert(_entry != null);
    _entry.remove();
    _entry = null;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
  }

  void _handlePointerEvent(PointerEvent event) {
    assert(_entry != null);
    if (event is PointerDownEvent)
      _controller.reverse();
  }

  @override
  void deactivate() {
    if (_entry != null)
      _controller.reverse();
    super.deactivate();
  }

  @override
  void dispose() {
    if (_entry != null)
      _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    final bool tooltipCreated = ensureTooltipVisible();
    if (tooltipCreated)
      Feedback.forLongPress(context);
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _handleLongPress,
      excludeFromSemantics: true,
      child: new Semantics(
        label: widget.message,
        child: widget.child,
      ),
    );
  }
}

/// A delegate for computing the layout of a XXX in the global coordinate system.
class _QuickStartPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  ///
  /// The arguments must not be null.
  _QuickStartPositionDelegate({
    @required this.targetRect,
  }) : assert(targetRect != null);

  /// The rectangle of the target the quick start tip is positioned near in the
  /// global coordinate system.
  final Rect targetRect;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    print('XXX ${targetRect.bottom}, $childSize');
    return new Offset(0.0, targetRect.top - childSize.height);
  }

  @override
  bool shouldRelayout(_QuickStartPositionDelegate oldDelegate) {
    return targetRect != oldDelegate.targetRect;
  }
}

class _QuickStartTooltipOverlay extends StatelessWidget {
  const _QuickStartTooltipOverlay({
    Key key,
    @required this.message,
    @required this.height,
    @required this.width,
    @required this.padding,
    @required this.targetRect,
    this.animation,
  }) : super(key: key);

  final String message;
  final double height;
  final double width;
  final EdgeInsetsGeometry padding;
  final Animation<double> animation;
  final Rect targetRect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ThemeData lightTheme = new ThemeData(
      brightness: Brightness.light,
      textTheme: theme.brightness == Brightness.dark ? theme.primaryTextTheme : theme.textTheme,
      platform: theme.platform,
    );
    return new Positioned.fill(
      child: new IgnorePointer(
          child: new FadeTransition(
            opacity: animation,
            child: new Opacity(
              opacity: 1.0,
              child: new AspectRatio(
                aspectRatio: 1.0,
                child: new CustomPaint(
                    painter: new QuickStartPainter(
                      color: lightTheme.primaryColor,
                      targetRect: targetRect,
                    ),
                  child: new CustomSingleChildLayout(
                    delegate: new _QuickStartPositionDelegate(
                      targetRect: targetRect,
                    ),
                    child: new Container(
                    padding: padding,
                    child: new Text(message, style: lightTheme.primaryTextTheme.title),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuickStartPainter extends CustomPainter {
  final Color color;
  final Rect targetRect;

  QuickStartPainter({
    @required this.color,
    @required this.targetRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print("Size = $size");
//    canvas.clipPath(clipPath);
//    canvas.drawCircle(offset, size.width, paint);
//
   final Path ovals = new Path()
     ..fillType= PathFillType.evenOdd
     ..addOval(targetRect.inflate(math.min(size.width, size.height)))
     ..addOval(targetRect);
    final Paint paint = new Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(ovals, paint);
  }

  @override
  bool shouldRepaint(QuickStartPainter oldPainter) {
    return true;
  }
}