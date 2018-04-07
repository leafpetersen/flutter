// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to show the text 'Hello, world.' using using the raw
// interface to the engine.

import 'dart:ui' as ui;

void beginFrame(Duration timeStamp) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  final ui.Size logicalSize = ui.window.physicalSize / devicePixelRatio;

  final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
    ui.ParagraphStyle(textDirection: ui.TextDirection.ltr),
  )..addText('Hello, world.');
  final ui.Paragraph paragraph = paragraphBuilder.build()
    ..layout(ui.ParagraphConstraints(width: logicalSize.width));

  final ui.Rect physicalBounds =
      ui.Offset.zero & (logicalSize * devicePixelRatio);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder, physicalBounds);
  canvas.scale(devicePixelRatio, devicePixelRatio);
  canvas.drawParagraph(
      paragraph,
      ui.Offset((logicalSize.width - paragraph.maxIntrinsicWidth) / 2.0,
          (logicalSize.height - paragraph.height) / 2.0));
  final ui.Picture picture = recorder.endRecording();

  final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
    // TODO(abarth): We should be able to add a picture without pushing a
    // container layer first.
    ..pushClipRect(physicalBounds)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();

  ui.window.render(sceneBuilder.build());
}

// This function is the primary entry point to your application. The engine
// calls main() as soon as it has loaded your code.
void main() {
  // The engine calls onBeginFrame whenever it wants us to produce a frame.
  ui.window.onBeginFrame = beginFrame;
  // Here we kick off the whole process by asking the engine to schedule a new
  // frame. The engine will eventually call onBeginFrame when it is time for us
  // to actually produce the frame.
  ui.window.scheduleFrame();
}
