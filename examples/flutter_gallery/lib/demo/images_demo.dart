import 'package:flutter/material.dart';

import '../gallery/demo.dart';

class ImagesDemo extends StatelessWidget {
  static const String routeName = '/images';

  @override
  Widget build(BuildContext context) {
    return TabbedComponentDemoScaffold(
        title: 'Animated images',
        demos: <ComponentDemoTabData>[
          ComponentDemoTabData(
            tabName: 'ANIMATED WEBP',
            description: '',
            exampleCodeTag: 'animated_image',
            demoWidget: Semantics(
              label: 'Example of animated WEBP',
              child: Image.asset(
                  'packages/flutter_gallery_assets/animated_flutter_stickers.webp'),
            ),
          ),
          ComponentDemoTabData(
            tabName: 'ANIMATED GIF',
            description: '',
            exampleCodeTag: 'animated_image',
            demoWidget: Semantics(
              label: 'Example of animated GIF',
              child: Image.asset(
                  'packages/flutter_gallery_assets/animated_flutter_lgtm.gif'),
            ),
          ),
        ]);
  }
}
