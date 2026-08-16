import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// `Image.network` has no built-in timeout: if a host accepts the TCP
/// connection but never responds (as via.placeholder.com does, now that
/// the service is discontinued), the widget hangs forever showing nothing
/// — `errorBuilder` never fires because no error ever occurs, it just never
/// completes. This fetches the bytes with an explicit timeout so a dead or
/// slow image host falls back to [fallback] within a bounded time instead
/// of leaving a blank box indefinitely.
class TimeoutNetworkImage extends StatelessWidget {
  const TimeoutNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.timeout = const Duration(seconds: 6),
  });

  final String url;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Duration timeout;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: http.get(Uri.parse(url)).timeout(timeout).then((r) => r.bodyBytes),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return fallback;
        if (snapshot.hasError || !snapshot.hasData) return fallback;
        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      },
    );
  }
}
