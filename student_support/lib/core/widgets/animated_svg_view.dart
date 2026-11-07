import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'motion.dart';

/// Plays an animated DiceBear SVG.
///
/// DiceBear animates with CSS inside the SVG, which flutter_svg does not run,
/// so this hands the SVG to a WebView. A WebView is expensive, so use this
/// only for one large image on a screen, never in a list.
///
/// [placeholder] (the static version) is shown until the page is ready, and
/// instead of the WebView when the platform has none, when the user turned
/// animations off, or when the tab is hidden. JavaScript stays off and the
/// content security policy blocks all loading: the SVG is third-party content.
class AnimatedSvgView extends StatelessWidget {
  final String svg;
  final Widget placeholder;

  const AnimatedSvgView({
    super.key,
    required this.svg,
    required this.placeholder,
  });

  static bool get isSupported => !kIsWeb && WebViewPlatform.instance != null;

  @visibleForTesting
  static String htmlFor(String svg) => '''
<!doctype html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'">
<style>html,body{margin:0;height:100%;overflow:hidden;background:transparent}svg{display:block;width:100%;height:100%}</style>
</head><body>$svg</body></html>''';

  @override
  Widget build(BuildContext context) {
    // Hidden IndexedStack tabs have tickers off, so no animation runs unseen.
    final play =
        isSupported &&
        motionAllowed(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!play) return placeholder;
    return _SvgWebView(key: ValueKey(svg), svg: svg, placeholder: placeholder);
  }
}

class _SvgWebView extends StatefulWidget {
  final String svg;
  final Widget placeholder;

  const _SvgWebView({super.key, required this.svg, required this.placeholder});

  @override
  State<_SvgWebView> createState() => _SvgWebViewState();
}

class _SvgWebViewState extends State<_SvgWebView> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => request.url == 'about:blank'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
          },
        ),
      )
      ..loadHtmlString(AnimatedSvgView.htmlFor(widget.svg));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.placeholder,
        // Decorative: touches pass through, and nothing is read out twice.
        ExcludeSemantics(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _ready ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ),
      ],
    );
  }
}
