import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class CoverCollageGenerator {
  static Future<Uint8List?> generateCollage(
    List<String> imageUrls, {
    int size = 400,
  }) async {
    if (imageUrls.isEmpty) return null;

    try {
      // Download images
      final images = <img.Image>[];
      for (final url in imageUrls.take(4)) {
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final image = img.decodeImage(response.bodyBytes);
            if (image != null) {
              images.add(image);
            }
          }
        } catch (e) {
          debugPrint('Error downloading image: $e');
        }
      }

      if (images.isEmpty) return null;

      // Create collage based on number of images
      final collage = _createCollage(images, size);
      if (collage == null) return null;

      // Encode as PNG
      return Uint8List.fromList(img.encodePng(collage));
    } catch (e) {
      debugPrint('Error generating collage: $e');
      return null;
    }
  }

  static img.Image? _createCollage(List<img.Image> images, int size) {
    if (images.isEmpty) return null;

    final collage = img.Image(width: size, height: size);
    img.fill(collage, color: img.ColorRgb8(20, 20, 20));

    if (images.length == 1) {
      // Single image - resize and center
      final resized = img.copyResize(images[0], width: size, height: size);
      img.compositeImage(collage, resized, dstX: 0, dstY: 0);
    } else if (images.length == 2) {
      // Two images - split vertically
      final halfSize = size ~/ 2;
      final img1 = img.copyResize(images[0], width: halfSize, height: size);
      final img2 = img.copyResize(images[1], width: halfSize, height: size);
      img.compositeImage(collage, img1, dstX: 0, dstY: 0);
      img.compositeImage(collage, img2, dstX: halfSize, dstY: 0);
    } else if (images.length == 3) {
      // Three images - one large, two small
      final halfSize = size ~/ 2;
      final img1 = img.copyResize(images[0], width: halfSize, height: size);
      final img2 = img.copyResize(images[1], width: halfSize, height: halfSize);
      final img3 = img.copyResize(images[2], width: halfSize, height: halfSize);
      img.compositeImage(collage, img1, dstX: 0, dstY: 0);
      img.compositeImage(collage, img2, dstX: halfSize, dstY: 0);
      img.compositeImage(collage, img3, dstX: halfSize, dstY: halfSize);
    } else {
      // Four or more images - 2x2 grid
      final halfSize = size ~/ 2;
      for (int i = 0; i < 4 && i < images.length; i++) {
        final resized = img.copyResize(
          images[i],
          width: halfSize,
          height: halfSize,
        );
        final x = (i % 2) * halfSize;
        final y = (i ~/ 2) * halfSize;
        img.compositeImage(collage, resized, dstX: x, dstY: y);
      }
    }

    return collage;
  }

  static Future<ui.Image?> generateFlutterImage(
    List<String> imageUrls, {
    int size = 400,
  }) async {
    final bytes = await generateCollage(imageUrls, size: size);
    if (bytes == null) return null;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
