import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

ImageProvider safeImageProvider(String? source) {
  if (source == null) {
    return const AssetImage('assets/images/profile.jpg');
  }

  String trimmed = source.trim();
  if (trimmed.isEmpty) {
    return const AssetImage('assets/images/profile.jpg');
  }

  // Remove potential surrounding quotes from backend strings
  if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
    trimmed = trimmed.substring(1, trimmed.length - 1).trim();
  }
  if (trimmed.startsWith("'") && trimmed.endsWith("'")) {
    trimmed = trimmed.substring(1, trimmed.length - 1).trim();
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
    return const AssetImage('assets/images/profile.jpg');
  }

  // Handle Network URL (more robust check)
  final lowerTrimmed = trimmed.toLowerCase();
  if (lowerTrimmed.startsWith('http://') || 
      lowerTrimmed.startsWith('https://') ||
      lowerTrimmed.startsWith('//')) {
    
    String url = trimmed;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }
    return CachedNetworkImageProvider(url);
  }

  // Check if it looks like a URL even if it doesn't start with http (e.g. ui-avatars.com)
  if (trimmed.contains('://') || (trimmed.contains('.') && trimmed.contains('/') && !trimmed.startsWith('assets/'))) {
     try {
       final uri = Uri.tryParse(trimmed);
       if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
         return CachedNetworkImageProvider(trimmed);
       }
     } catch (_) {}
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

  const SafeImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (source == null) {
      return _errorWidget();
    }

    String trimmed = source!.trim();
    if (trimmed.isEmpty) {
      return _errorWidget();
    }

    // Remove potential surrounding quotes from backend strings
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }
    if (trimmed.startsWith("'") && trimmed.endsWith("'")) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }

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
            errorBuilder: (context, error, stackTrace) => _errorWidget(),
          );
        }
      } catch (e) {
        return _errorWidget();
      }
    }

    final lowerTrimmed = trimmed.toLowerCase();
    bool isNetwork = lowerTrimmed.startsWith('http://') || 
                     lowerTrimmed.startsWith('https://') ||
                     lowerTrimmed.startsWith('//');
    
    if (!isNetwork && (trimmed.contains('://') || (trimmed.contains('.') && trimmed.contains('/') && !trimmed.startsWith('assets/')))) {
       try {
         final uri = Uri.tryParse(trimmed);
         if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
           isNetwork = true;
         }
       } catch (_) {}
    }

    if (isNetwork) {
      String url = trimmed;
      if (url.startsWith('//')) {
        url = 'https:$url';
      }
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _loadingWidget(),
        errorWidget: (context, url, error) => _errorWidget(),
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
      errorBuilder: (context, error, stackTrace) => _errorWidget(),
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

  Widget _errorWidget() {
    return errorBuilder ??
        Container(
          width: width,
          height: height,
          color: Colors.black12,
          child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
        );
  }
}
