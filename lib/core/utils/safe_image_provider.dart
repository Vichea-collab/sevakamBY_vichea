import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_env.dart';

final Uint8List _transparentPixel = base64Decode(
  'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
);

String _sanitizeImageSource(String source) {
  String trimmed = source.trim();
  if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
    trimmed = trimmed.substring(1, trimmed.length - 1).trim();
  }
  if (trimmed.startsWith("'") && trimmed.endsWith("'")) {
    trimmed = trimmed.substring(1, trimmed.length - 1).trim();
  }
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('//')) {
    trimmed = 'https:$trimmed';
  } else if (trimmed.toLowerCase().startsWith('www.')) {
    trimmed = 'https://$trimmed';
  }
  if (trimmed.contains(' ')) {
    trimmed = Uri.encodeFull(trimmed);
  }
  return trimmed;
}

ImageProvider safeImageProvider(String? source) {
  if (source == null || source.trim().isEmpty) {
    return MemoryImage(_transparentPixel);
  }

  final trimmed = _sanitizeImageSource(source);

  if (trimmed.isEmpty) {
    return MemoryImage(_transparentPixel);
  }

  // Handle Data URI (base64)
  if (trimmed.toLowerCase().startsWith('data:image')) {
    try {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1) {
        final base64String = trimmed.substring(commaIndex + 1);
        return MemoryImage(base64Decode(base64String));
      }
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
    }
    return MemoryImage(_transparentPixel);
  }

  // Handle Network URL (more robust check)
  final lowerTrimmed = trimmed.toLowerCase();
  if (lowerTrimmed.startsWith('http://') ||
      lowerTrimmed.startsWith('https://') ||
      lowerTrimmed.startsWith('//') ||
      lowerTrimmed.startsWith('www.')) {
    return CachedNetworkImageProvider(trimmed);
  }

  // Check if it's an explicit network URL
  if (trimmed.contains('://') ||
      (trimmed.contains('.') &&
          trimmed.contains('/') &&
          !trimmed.startsWith('assets/'))) {
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https')) {
        return CachedNetworkImageProvider(trimmed);
      }
    } catch (_) {}
  }

  // If it's not a local asset, assume it's a relative path to the backend
  if (!lowerTrimmed.startsWith('assets/')) {
    final baseUrl = AppEnv.apiBaseUrl();
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = trimmed.startsWith('/')
        ? '$cleanBase$trimmed'
        : '$cleanBase/$trimmed';
    return CachedNetworkImageProvider(url);
  }

  // Fallback to Asset
  return AssetImage(trimmed);
}

class SafeImage extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorBuilder;
  final bool isAvatar;

  const SafeImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
    this.isAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (source == null) {
      return _errorWidget(context);
    }

    String trimmed = source!.trim();
    if (trimmed.isEmpty) {
      return _errorWidget(context);
    }

    trimmed = _sanitizeImageSource(trimmed);

    if (trimmed.toLowerCase().startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        if (commaIndex != -1) {
          final base64String = trimmed.substring(commaIndex + 1);
          return Image.memory(
            base64Decode(base64String),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _errorWidget(context),
          );
        }
      } catch (e) {
        return _errorWidget(context);
      }
    }

    final lowerTrimmed = trimmed.toLowerCase();
    bool isNetwork =
        lowerTrimmed.startsWith('http://') ||
        lowerTrimmed.startsWith('https://') ||
        lowerTrimmed.startsWith('//') ||
        lowerTrimmed.startsWith('www.');

    String url = trimmed;

    if (!isNetwork &&
        (trimmed.contains('://') ||
            (trimmed.contains('.') &&
                trimmed.contains('/') &&
                !trimmed.startsWith('assets/')))) {
      try {
        final uri = Uri.tryParse(trimmed);
        if (uri != null &&
            uri.hasScheme &&
            (uri.scheme == 'http' || uri.scheme == 'https')) {
          isNetwork = true;
        }
      } catch (_) {}
    }

    if (!isNetwork && !lowerTrimmed.startsWith('assets/')) {
      isNetwork = true;
      final baseUrl = AppEnv.apiBaseUrl();
      final cleanBase = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      url = trimmed.startsWith('/')
          ? '$cleanBase$trimmed'
          : '$cleanBase/$trimmed';
    }

    if (isNetwork) {
      if (kIsWeb) {
        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _errorWidget(context),
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        );
      }
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _loadingWidget(),
        errorWidget: (context, url, error) => _errorWidget(context),
        // Fade in is smoother than immediate replacement
        fadeInDuration: const Duration(milliseconds: 250),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    }

    // Fallback to asset
    return Image.asset(
      trimmed,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _errorWidget(context),
    );
  }

  Widget _loadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.black12,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _errorWidget(BuildContext context) {
    if (errorBuilder != null) return errorBuilder!;
    if (isAvatar) {
      final size = width ?? height ?? 40;
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFFEAF1FF),
        child: Icon(
          Icons.person,
          color: Theme.of(context).primaryColor,
          size: size * 0.5,
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      color: Colors.black12,
      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
    );
  }
}
