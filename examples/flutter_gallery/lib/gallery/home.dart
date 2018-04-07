// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'drawer.dart';
import 'item.dart';
import 'theme.dart';

const double _kFlexibleSpaceMaxHeight = 256.0;
const String _kGalleryAssetsPackage = 'flutter_gallery_assets';

class _BackgroundLayer {
  _BackgroundLayer({int level, double parallax})
      : assetName = 'appbar/appbar_background_layer$level.png',
        assetPackage = _kGalleryAssetsPackage,
        parallaxTween = Tween<double>(begin: 0.0, end: parallax);
  final String assetName;
  final String assetPackage;
  final Tween<double> parallaxTween;
}

final List<_BackgroundLayer> _kBackgroundLayers = <_BackgroundLayer>[
  _BackgroundLayer(level: 0, parallax: _kFlexibleSpaceMaxHeight),
  _BackgroundLayer(level: 1, parallax: _kFlexibleSpaceMaxHeight),
  _BackgroundLayer(level: 2, parallax: _kFlexibleSpaceMaxHeight / 2.0),
  _BackgroundLayer(level: 3, parallax: _kFlexibleSpaceMaxHeight / 4.0),
  _BackgroundLayer(level: 4, parallax: _kFlexibleSpaceMaxHeight / 2.0),
  _BackgroundLayer(level: 5, parallax: _kFlexibleSpaceMaxHeight)
];

class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({Key key, this.animation}) : super(key: key);

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget child) {
          return Stack(
              children: _kBackgroundLayers.map((_BackgroundLayer layer) {
            return Positioned(
                top: -layer.parallaxTween.evaluate(animation),
                left: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: Image.asset(layer.assetName,
                    package: layer.assetPackage,
                    fit: BoxFit.cover,
                    height: _kFlexibleSpaceMaxHeight));
          }).toList());
        });
  }
}

class GalleryHome extends StatefulWidget {
  const GalleryHome({
    Key key,
    this.galleryTheme,
    @required this.onThemeChanged,
    this.timeDilation,
    @required this.onTimeDilationChanged,
    this.textScaleFactor,
    this.onTextScaleFactorChanged,
    this.showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged,
    this.checkerboardRasterCacheImages,
    this.onCheckerboardRasterCacheImagesChanged,
    this.checkerboardOffscreenLayers,
    this.onCheckerboardOffscreenLayersChanged,
    this.onPlatformChanged,
    this.overrideDirection: TextDirection.ltr,
    this.onOverrideDirectionChanged,
    this.onSendFeedback,
  })  : assert(onThemeChanged != null),
        assert(onTimeDilationChanged != null),
        super(key: key);

  final GalleryTheme galleryTheme;
  final ValueChanged<GalleryTheme> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final double textScaleFactor;
  final ValueChanged<double> onTextScaleFactorChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  final bool checkerboardRasterCacheImages;
  final ValueChanged<bool> onCheckerboardRasterCacheImagesChanged;

  final bool checkerboardOffscreenLayers;
  final ValueChanged<bool> onCheckerboardOffscreenLayersChanged;

  final ValueChanged<TargetPlatform> onPlatformChanged;

  final TextDirection overrideDirection;
  final ValueChanged<TextDirection> onOverrideDirectionChanged;

  final VoidCallback onSendFeedback;

  @override
  GalleryHomeState createState() => GalleryHomeState();
}

class GalleryHomeState extends State<GalleryHome>
    with SingleTickerProviderStateMixin {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      debugLabel: 'preview banner',
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _galleryListItems() {
    final List<Widget> listItems = <Widget>[];
    final ThemeData themeData = Theme.of(context);
    final TextStyle headerStyle =
        themeData.textTheme.body2.copyWith(color: themeData.accentColor);
    String category;
    for (GalleryItem galleryItem in kAllGalleryItems) {
      if (category != galleryItem.category) {
        if (category != null) listItems.add(const Divider());
        listItems.add(MergeSemantics(
          child: Container(
            height: 48.0,
            padding: const EdgeInsetsDirectional.only(start: 16.0),
            alignment: AlignmentDirectional.centerStart,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Semantics(
                header: true,
                child: Text(galleryItem.category, style: headerStyle),
              ),
            ),
          ),
        ));
        category = galleryItem.category;
      }
      listItems.add(galleryItem);
    }
    return listItems;
  }

  @override
  Widget build(BuildContext context) {
    Widget home = Scaffold(
        key: _scaffoldKey,
        drawer: GalleryDrawer(
          galleryTheme: widget.galleryTheme,
          onThemeChanged: widget.onThemeChanged,
          timeDilation: widget.timeDilation,
          onTimeDilationChanged: widget.onTimeDilationChanged,
          textScaleFactor: widget.textScaleFactor,
          onTextScaleFactorChanged: widget.onTextScaleFactorChanged,
          showPerformanceOverlay: widget.showPerformanceOverlay,
          onShowPerformanceOverlayChanged:
              widget.onShowPerformanceOverlayChanged,
          checkerboardRasterCacheImages: widget.checkerboardRasterCacheImages,
          onCheckerboardRasterCacheImagesChanged:
              widget.onCheckerboardRasterCacheImagesChanged,
          checkerboardOffscreenLayers: widget.checkerboardOffscreenLayers,
          onCheckerboardOffscreenLayersChanged:
              widget.onCheckerboardOffscreenLayersChanged,
          onPlatformChanged: widget.onPlatformChanged,
          overrideDirection: widget.overrideDirection,
          onOverrideDirectionChanged: widget.onOverrideDirectionChanged,
          onSendFeedback: widget.onSendFeedback,
        ),
        body: CustomScrollView(
          slivers: <Widget>[
            const SliverAppBar(
              pinned: true,
              expandedHeight: _kFlexibleSpaceMaxHeight,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Flutter Gallery'),
                // TODO(abarth): Wire up to the parallax in a way that doesn't pop during hero transition.
                background:
                    _AppBarBackground(animation: kAlwaysDismissedAnimation),
              ),
            ),
            SliverList(delegate: SliverChildListDelegate(_galleryListItems())),
          ],
        ));

    // In checked mode our MaterialApp will show the default "debug" banner.
    // Otherwise show the "preview" banner.
    bool showPreviewBanner = true;
    assert(() {
      showPreviewBanner = false;
      return true;
    }());

    if (showPreviewBanner) {
      home = Stack(fit: StackFit.expand, children: <Widget>[
        home,
        FadeTransition(
            opacity:
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            child: const Banner(
              message: 'PREVIEW',
              location: BannerLocation.topEnd,
            )),
      ]);
    }

    return home;
  }
}
