// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui show window, Picture, SceneBuilder, PictureRecorder;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // XXX cyclic dep.
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';

void truncateLines(String txt, int lines) {
  final List<String> parts = txt.split('\n');

  for (int i = 0; i < math.min(parts.length, lines); ++i) {
    var line = parts[i];
    if (i == lines - 1 && lines < parts.length) {
      print('$line ...');
    } else {
      print(line);
    }
  }
}

/// Signature for the builder callback used by
/// [WidgetInspector.selectButtonBuilder].
typedef Widget InspectorSelectButtonBuilder(BuildContext context, VoidCallback onPressed);

/// A widget that enables inspecting the child widget's structure.
///
/// Select a location on your device or emulator and view what widgets and
/// render object that best matches the location. An outline of the selected
/// widget and terse summary information is shown on device with detailed
/// information is shown in the observatory or in IntelliJ when using the
/// Flutter Plugin.
///
/// The inspector has a select mode and a view mode.
///
/// In the select mode, tapping the device selects the widget that best matches
/// the location of the touch and switches to view mode. Dragging a finger on
/// the device selects the widget under the drag location but does not switch
/// modes. Touching the very edge of the bounding box of a widget triggers
/// selecting the widget even if another widget that also overlaps that
/// location would otherwise have priority.
///
/// In the view mode, the previously selected widget is outlined, however,
/// touching the device has the same effect it would have if the inspector
/// wasn't present. This allows interacting with the application and viewing how
/// the selected widget changes position. Clicking on the select icon in the
/// bottom left corner of the application switches back to select mode.
class WidgetInspector extends StatefulWidget {
  /// Creates a widget that enables inspection for the child.
  ///
  /// The [child] argument must not be null.
  const WidgetInspector({
    Key key,
    @required this.child,
    @required this.selectButtonBuilder,
  }) : assert(child != null),
       super(key: key);

  /// The widget that is being inspected.
  final Widget child;

  /// A builder that is called to create the select button.
  ///
  /// The `onPressed` callback passed as an argument to the builder should be
  /// hooked up to the returned widget.
  final InspectorSelectButtonBuilder selectButtonBuilder;

  @override
  _WidgetInspectorState createState() => new _WidgetInspectorState();
}

_WidgetInspectorState debugInspector;

class _WidgetInspectorState extends State<WidgetInspector>
    with WidgetsBindingObserver {

  _WidgetInspectorState() : selection = new InspectorSelection() {
    debugInspector = this; /// XXX hack.
  }

  Offset _lastPointerLocation;

  final InspectorSelection selection;

  void callAction(String action) {
    if (selection.candidates == null)
      return;
    switch (action) {
      case 'up':
        setState(() {
          selection.index = (selection.index + 1) % selection.candidates.length;
        });
        describeCurrent();
        break;
      case 'down':
        setState(() {
          selection.index =
              (selection.index - 1 + selection.candidates.length) %
                  selection.candidates.length;
        });
        describeCurrent();
        break;
      case 'parent':
        setState(() {
          if (selection.current == null || selection.current.parent == null) {
            print("No parent.");
            return;
          }
          selection.current = selection.current.parent;
          describeCurrent();
        });
        break;
      case 'back':
        setState(() {
          selection.pop();
          describeCurrent();
        });
        break;
      case 'inspect':
        describeCurrent(10000);
        break;
      case 'refresh':
        describeCurrent();
        break;
    }
  }
  /// Whether the inspector is in select mode.
  ///
  /// In select mode, pointer interactions trigger widget selection instead of
  /// normal interactions. Otherwise the previously selected widget is
  /// highlighted but the application can be interacted with normally.
  bool isSelectMode = true;

  final GlobalKey _ignorePointerKey = new GlobalKey();

  /// Distance from the edge of of the bounding box for an element to consider
  /// as selecting the edge of the bounding box.
  static const double _kEdgeHitMargin = 2.0;

  bool _hitTestHelper(
    List<RenderObject> hits,
    List<RenderObject> edgeHits,
    Offset position,
    RenderObject object,
    Matrix4 transform,
  ) {
    bool hit = false;
    final Matrix4 inverse = new Matrix4.inverted(transform);
    final Offset localPosition = MatrixUtils.transformPoint(inverse, position);

    final List<DiagnosticsNode> children = object.debugDescribeChildren();
    for (int i = children.length - 1; i >= 0; i -= 1) {
      final DiagnosticsNode diagnostics = children[i];
      assert(diagnostics != null);
      if (diagnostics.style == DiagnosticsTreeStyle.offstage ||
          diagnostics.value is! RenderObject)
        continue;
      final RenderObject child = diagnostics.value;
      final Rect paintClip = object.describeApproximatePaintClip(child);
      if (paintClip != null && !paintClip.contains(localPosition))
        continue;

      final Matrix4 childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      if (_hitTestHelper(hits, edgeHits, position, child, childTransform))
        hit = true;
    }

    final Rect bounds = object.semanticBounds;
    if (bounds.contains(localPosition)) {
      hit = true;
      // Hits that occur on the edge of the bounding box of an object are
      // given priority to provide a way to select objects that would
      // otherwise be hard to select.
      if (!bounds.deflate(_kEdgeHitMargin).contains(localPosition))
        edgeHits.add(object);
    }
    if (hit)
      hits.add(object);
    return hit;
  }

  /// Returns the list of render objects located at the given position ordered
  /// by priority.
  ///
  /// All render objects that are not offstage that match the location are
  /// included in the list of matches. Priority is given to matches that occur
  /// on the edge of a render object's bounding box and to matches found by
  /// [RenderBox.hitTest].
  List<RenderObject> hitTest(Offset position, RenderObject root) {
    final List<RenderObject> regularHits = <RenderObject>[];
    final List<RenderObject> edgeHits = <RenderObject>[];

    _hitTestHelper(regularHits, edgeHits, position, root, root.getTransformTo(null));
    // Order matches by the size of the hit area.
    double _area(RenderObject object) {
      final Size size = object.semanticBounds?.size;
      return size == null ? double.MAX_FINITE : size.width * size.height;
    }
    Set<RenderObject> regularHitsSet = new HashSet<RenderObject>();
    regularHitsSet.addAll(regularHits);
    regularHits.sort((RenderObject a, RenderObject b) => _area(a).compareTo(_area(b)));
    bool noChildrenHit(RenderObject object) {
      bool hitChild = false;
      object.visitChildren((RenderObject child) {
        if (regularHitsSet.contains(child))
          hitChild = true;
      });
      return !hitChild;
    }
    final Set<RenderObject> hits = new LinkedHashSet<RenderObject>();
    hits..addAll(edgeHits)..addAll(regularHits.where(noChildrenHit));
    return hits.toList();
  }

  void _inspectAt(Offset position) {
    if (!isSelectMode)
      return;

    final RenderIgnorePointer ignorePointer = _ignorePointerKey.currentContext.findRenderObject();
    final RenderObject userRender = ignorePointer.child;
    final List<RenderObject> selected = hitTest(position, userRender);

    setState(() {
      selection.candidates = selected;
    });
  }

  void _handlePanDown(DragDownDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    // If the pan ends on the edge of the window assume that it indicates the
    // pointer is being dragged off the edge of the display not a regular touch
    // on the edge of the display. If the pointer is being dragged off the edge
    // of the display we do not want to select anything. A user can still select
    // a widget that is only at the exact screen margin by tapping.
    final Rect bounds = (Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio)).deflate(_kOffScreenMargin);
    if (!bounds.contains(_lastPointerLocation)) {
      setState(() {
        selection.clear();
      });
    }
  }

  void _handleTap(BuildContext context) {
    if (!isSelectMode)
      return;
    if (_lastPointerLocation != null) {
      final RenderObject lastSelection = selection?.current;
      _inspectAt(_lastPointerLocation);

      if (selection != null) {
        if (lastSelection != selection.current) {
          // Notify debuggers to open an inspector on the object.
         /* selection.current?.markNeedsPaint();
          lastSelection?.markNeedsPaint();*/
        }
        describeCurrent();
      }
    }
    setState(() {
      // Only exit select mode if there is a button to return to select mode.
      if (widget.selectButtonBuilder != null)
        isSelectMode = false;
    });
    Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Padding(
          // Padding so we don't hide the inspect icon.
          padding: new EdgeInsets.only(left: 35.0),
          child: const Text('Exiting select mode.\nTap the inspect icon to enter.'),
        ),
        duration: const Duration(milliseconds: 2000),
        backgroundColor: const Color.fromARGB(200, 0, 0, 0),
    ));
  }

  void describeCurrent([int maxLength=27]) {
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print(' ');
    print('${selection.index + 1} of ${selection.candidates.length}');
//    print('===============================================================');
    if (selection.current == null)
      return;
    if (maxLength > 30)
      developer.inspect(selection.current);

    print("===================== Render Object Tree ====================");
    String debugRenderObjectParentChain(RenderObject node, int limit) {
      List<String> chain = <String>[];
      if (node != null) node = node.parent;
      while (chain.length < limit && node != null) {
        chain.add(node.toStringShort());
        node = node.parent;
      }
      if (node != null)
        chain.add('\u22EF');
      chain = chain.reversed.toList();
      if (chain.length > 0) chain.add(' ');
      return chain.join(' \u2192 ');
    }
  print(debugRenderObjectParentChain(selection.current, maxLength~/6));
    truncateLines(selection.current.toStringDeep(), maxLength);
    final Element creator = selection.current.debugCreator.element;

    if (creator != null) {
      print('======================== Widget Tree ========================');
      print(creator.debugGetCreatorChainR(maxLength~/6));
      truncateLines(creator.toStringDeep(), maxLength ~/ 3);
    }
    if (maxLength > 30)
      developer.inspect(creator);
  }

  void _handleEnableSelect(BuildContext context) {
    setState(() {
      isSelectMode = true;
    });
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: const Text('Tap a widget to select it'),
      backgroundColor: const Color.fromARGB(200, 0, 0, 0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return new MediaQuery(
      data: new MediaQueryData.fromWindow(ui.window),
      child: new Scaffold(
        body: new Builder(
          builder: (BuildContext context) {
            final List<Widget> children = <Widget>[];
            children.add(new GestureDetector(
              onTap: () => _handleTap(context),
              onPanDown: _handlePanDown,
              onPanEnd: _handlePanEnd,
              onPanUpdate: _handlePanUpdate,
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              child: new IgnorePointer(
                ignoring: isSelectMode,
                key: _ignorePointerKey,
                ignoringSemantics: false,
                child: widget.child,
              ),
            ));
            if (!isSelectMode && widget.selectButtonBuilder != null) {
              children.add(new Positioned(
                  left: _kInspectButtonMargin,
                  bottom: _kInspectButtonMargin,
                  child:  widget.selectButtonBuilder(context, () => _handleEnableSelect(context))
              ));
            }
            children.add(new _InspectorOverlay(selection: selection));
            return new Stack(children: children);
          },
        ),
      ),
    );
  }
}

/// Mutable selection state of the inspector.
class InspectorSelection {
  /// Render objects that are candidates to be selected.
  ///
  /// Tools may wish to iterate through the list of candidates.
  List<RenderObject> get candidates => _candidates;
  List<RenderObject> _candidates = <RenderObject>[];
  List<RenderObject> undoStack = <RenderObject>[];
  set candidates(List<RenderObject> value) {
    _candidates = value;
    _index = 0;
    _calculateCurrent();
    undoStack = <RenderObject>[];
  }

  /// Index within the list of candidates that is currently selected.
  int get index => _index;
  void set index(int value) {
    _index = value;
    _calculateCurrent();
  }
  int _index = 0;

  /// Set the selection to empty.
  void clear() {
    _candidates = <RenderObject>[];
    index = 0;
    _calculateCurrent();
  }

  /// Selected render object from the [candidates] list.
  ///
  /// Setting [candidates] or calling [clear] resets the selection.
  ///
  /// Returns null if the selection is invalid.
  RenderObject get current => _current;
  RenderObject _current;
  void set current(RenderObject v) {
    if (_current != null) {
      undoStack.add(_current);
    }
    _current = v;
  }

  void pop() {
    if (undoStack.isEmpty) return;
    _current = undoStack.removeLast();
  }

  void _calculateCurrent() {
    _current = candidates != null && index < candidates.length ? candidates[index] : null;
    undoStack = <RenderObject>[];
  }

  /// Whether the selected render object is attached to the tree or has gone
  /// out of scope.
  bool get active => current != null && current.attached;
}

class _InspectorOverlay extends LeafRenderObjectWidget {
  const _InspectorOverlay({
    Key key,
    @required this.selection,
  }) : super(key: key);

  final InspectorSelection selection;

  @override
  _RenderInspectorOverlay createRenderObject(BuildContext context) {
    return new _RenderInspectorOverlay(selection: selection);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInspectorOverlay renderObject) {
    renderObject.selection = selection;
  }
}

class _RenderInspectorOverlay extends RenderBox {
  /// The arguments must not be null.
  _RenderInspectorOverlay({ @required InspectorSelection selection }) : _selection = selection, assert(selection != null);

  InspectorSelection get selection => _selection;
  InspectorSelection _selection;
  set selection(InspectorSelection value) {
    if (value != _selection) {
      _selection = value;
    }
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performResize() {
    size = constraints.constrain(const Size(double.INFINITY, double.INFINITY));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    context.addLayer(new _InspectorOverlayLayer(
      overlayRect: new Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      selection: selection,
    ));
  }
}

class _TransformedRect {
  _TransformedRect(RenderObject object) :
    rect = object.semanticBounds,
    transform = object.getTransformTo(null);

  final Rect rect;
  final Matrix4 transform;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final _TransformedRect typedOther = other;
    return rect == typedOther.rect && transform == typedOther.transform;
  }

  @override
  int get hashCode => hashValues(rect, transform);
}

/// State describing how the inspector overlay should be rendered.
///
/// The equality operator can be used to determine whether the overlay needs to
/// be rendered again.
class _InspectorOverlayRenderState {
  _InspectorOverlayRenderState({
    @required this.overlayRect,
    @required this.selected,
    @required this.candidates,
    @required this.tooltip,
    @required this.textDirection,
    @required this.selectedObject,
  });

  final Rect overlayRect;
  final _TransformedRect selected;
  final List<_TransformedRect> candidates;
  final String tooltip;
  final TextDirection textDirection;
  final RenderObject selectedObject;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;

    final _InspectorOverlayRenderState typedOther = other;
    return overlayRect == typedOther.overlayRect
        && selected == typedOther.selected
        && listEquals<_TransformedRect>(candidates, typedOther.candidates)
        && tooltip == typedOther.tooltip;
  }

  @override
  int get hashCode => hashValues(overlayRect, selected, hashList(candidates), tooltip);
}

const int _kMaxTooltipLines = 5;
const Color _kTooltipBackgroundColor = const Color.fromARGB(230, 60, 60, 60);
const Color _kHighlightedRenderObjectFillColor = const Color.fromARGB(64, 128, 128, 255);
const Color _kHighlightedRenderObjectBorderColor = const Color.fromARGB(128, 64, 64, 128);

/// A layer that outlines the selected [RenderObject] and candidate render
/// objects that also match the last pointer location.
///
/// This approach is horrific for performance and is only used here because this
/// is limited to debug mode. Do not duplicate the logic in production code.
class _InspectorOverlayLayer extends Layer {
  /// Creates a layer that displays the inspector overlay.
  _InspectorOverlayLayer({
    @required this.overlayRect,
    @required this.selection,
  }) : assert(overlayRect != null), assert(selection != null) {
    bool inDebugMode = false;
    assert(() {
      inDebugMode = true;
      return true;
    });
    if (inDebugMode == false) {
      throw new FlutterError(
        'The inspector should never be used in production mode due to the '
        'negative performance impact.'
      );
    }
  }

  InspectorSelection selection;

  /// The rectangle in this layer's coordinate system that the overlay should
  /// occupy.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  final Rect overlayRect;

  _InspectorOverlayRenderState _lastState;

  /// Picture generated from _lastState.
  ui.Picture _picture;

  TextPainter _textPainter;
  double _textPainterMaxWidth;

  @override
  void addToScene(ui.SceneBuilder builder, Offset layerOffset) {
    if (!selection.active)
      return;

    final RenderObject selected = selection.current;
    final List<_TransformedRect> candidates = <_TransformedRect>[];
    for (RenderObject candidate in selection.candidates) {
      if (candidate == selected || !candidate.attached)
        continue;
      candidates.add(new _TransformedRect(candidate));
    }

    final _InspectorOverlayRenderState state = new _InspectorOverlayRenderState(
      overlayRect: overlayRect,
      selected: new _TransformedRect(selected),
      tooltip: selected.toString(),
      textDirection: TextDirection.ltr,
      candidates: candidates,
      selectedObject: selected,
    );

    if (state != _lastState) {
      _lastState = state;
      _picture = _buildPicture(state);
    }
    builder.addPicture(layerOffset, _picture);
  }

  ui.Picture _buildPicture(_InspectorOverlayRenderState state) {
    final ui.PictureRecorder recorder = new ui.PictureRecorder();
    final Canvas canvas = new Canvas(recorder, state.overlayRect);
    final Size size = state.overlayRect.size;

    final Paint fillPaint = new Paint()
      ..style = PaintingStyle.fill
      ..color = _kHighlightedRenderObjectFillColor;

    final Paint borderPaint = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _kHighlightedRenderObjectBorderColor;

    // Highlight the selected renderObject.
    final Rect selectedPaintRect = state.selected.rect.deflate(0.5);
    canvas
      ..save()
      ..transform(state.selected.transform.storage);

    canvas
      ..drawRect(selectedPaintRect, fillPaint)
      ..drawRect(selectedPaintRect, borderPaint);

    final bool oldDebugPaintSizeEnabled = debugPaintSizeEnabled;
    debugPaintSizeEnabled = true;
    state.selectedObject?.debugPaint(canvas, const Offset(0.0, 0.0));
    debugPaintSizeEnabled = oldDebugPaintSizeEnabled;
    canvas.restore();

    // Show all other candidate possibly selected elements. This helps selecting
    // render objects by selecting the edge of the bounding box shows all
    // elements the user could toggle the selection between.
    for (_TransformedRect transformedRect in state.candidates) {
      canvas
        ..save()
        ..transform(transformedRect.transform.storage)
        ..drawRect(transformedRect.rect.deflate(0.5), borderPaint)
        ..restore();
    }

    final Rect targetRect = MatrixUtils.transformRect(
        state.selected.transform, state.selected.rect);
    final Offset target = new Offset(targetRect.left, targetRect.center.dy);
    final double offsetFromWidget = 9.0;
    final double verticalOffset = (targetRect.height) / 2 + offsetFromWidget;

    _paintDescription(canvas, state.tooltip, state.textDirection, target, verticalOffset, size, targetRect);

    // TODO(jacobr): provide an option to perform a debug paint of just the
    // selected widget.
    return recorder.endRecording();
  }

  void _paintDescription(
    Canvas canvas,
    String message,
    TextDirection textDirection,
    Offset target,
    double verticalOffset,
    Size size,
    Rect targetRect,
  ) {
    canvas.save();
    final double maxWidth = size.width - 2 * (_kScreenEdgeMargin + _kTooltipPadding);
    if (_textPainter == null || _textPainter.text.text != message || _textPainterMaxWidth != maxWidth) {
      _textPainterMaxWidth = maxWidth;
      _textPainter = new TextPainter()
        ..maxLines = _kMaxTooltipLines
        ..ellipsis = '...'
        ..text = new TextSpan(style: _messageStyle, text: message)
        ..textDirection = textDirection
        ..layout(maxWidth: maxWidth);
    }

    final Size tooltipSize = _textPainter.size + const Offset(_kTooltipPadding * 2, _kTooltipPadding * 2);
    final Offset tipOffset = positionDependentBox(
      size: size,
      childSize: tooltipSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: false,
    );

    final Paint tooltipBackground = new Paint()
      ..style = PaintingStyle.fill
      ..color = _kTooltipBackgroundColor;
    canvas.drawRect(
      new Rect.fromPoints(
        tipOffset,
        tipOffset.translate(tooltipSize.width, tooltipSize.height),
      ),
      tooltipBackground,
    );

    double wedgeY = tipOffset.dy;
    final bool tooltipBelow = tipOffset.dy > target.dy;
    if (!tooltipBelow)
      wedgeY += tooltipSize.height;

    final double wedgeSize = _kTooltipPadding * 2;
    double wedgeX = math.max(tipOffset.dx, target.dx) + wedgeSize * 2;
    wedgeX = math.min(wedgeX, tipOffset.dx + tooltipSize.width - wedgeSize * 2);
    final List<Offset> wedge = <Offset>[
      new Offset(wedgeX - wedgeSize, wedgeY),
      new Offset(wedgeX + wedgeSize, wedgeY),
      new Offset(wedgeX, wedgeY + (tooltipBelow ? -wedgeSize : wedgeSize)),
    ];
    canvas.drawPath(new Path()..addPolygon(wedge, true,), tooltipBackground);
    _textPainter.paint(canvas, tipOffset + const Offset(_kTooltipPadding, _kTooltipPadding));
    canvas.restore();
  }
}

const double _kScreenEdgeMargin = 10.0;
const double _kTooltipPadding = 5.0;
const double _kInspectButtonMargin = 10.0;

/// Interpret pointer up events within with this margin as indicating the
/// pointer is moving off the device.
const double _kOffScreenMargin = 1.0;

const TextStyle _messageStyle = const TextStyle(
  color: const Color(0xFFFFFFFF),
  fontSize: 10.0,
  height: 1.2,
);
