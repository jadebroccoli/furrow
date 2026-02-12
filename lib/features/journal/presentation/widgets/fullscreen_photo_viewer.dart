import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fullscreen photo viewer with pinch-to-zoom and swipe-to-dismiss.
///
/// Opened via [Navigator.push] with an opaque-false [PageRouteBuilder]
/// so the Hero animation works and the previous route peeks through
/// during the dismiss drag.
class FullscreenPhotoViewer extends StatefulWidget {
  const FullscreenPhotoViewer({
    super.key,
    required this.photoPath,
    required this.heroTag,
    this.caption,
  });

  final String photoPath;
  final String heroTag;
  final String? caption;

  @override
  State<FullscreenPhotoViewer> createState() => _FullscreenPhotoViewerState();
}

class _FullscreenPhotoViewerState extends State<FullscreenPhotoViewer>
    with SingleTickerProviderStateMixin {
  final _transformController = TransformationController();
  late final AnimationController _animController;

  double _dragOffset = 0.0;
  double _opacity = 1.0;

  bool get _isZoomed =>
      _transformController.value.getMaxScaleOnAxis() > 1.05;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Light status bar icons on dark background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    // Restore default (will be overridden by the theme anyway)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() {
      _dragOffset += details.delta.dy;
      _opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.2, 1.0);
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy.abs();
    if (_dragOffset.abs() > 100 || velocity > 500) {
      Navigator.of(context).pop();
    } else {
      // Snap back
      setState(() {
        _dragOffset = 0;
        _opacity = 1.0;
      });
    }
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      // Reset to original scale
      _transformController.value = Matrix4.identity();
    } else {
      // Zoom to 2.5x at center using Matrix4 factory
      final size = MediaQuery.of(context).size;
      final dx = -size.width * 0.75; // center offset for 2.5x
      final dy = -size.height * 0.75;
      _transformController.value = Matrix4(
        2.5, 0, 0, 0, //
        0, 2.5, 0, 0, //
        0, 0, 1, 0, //
        dx, dy, 0, 1, //
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.photoPath);
    final fileExists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: _isZoomed ? null : _handleVerticalDragUpdate,
        onVerticalDragEnd: _isZoomed ? null : _handleVerticalDragEnd,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _opacity,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Center(
                    child: fileExists
                        ? GestureDetector(
                            onDoubleTap: _handleDoubleTap,
                            child: Hero(
                              tag: widget.heroTag,
                              child: InteractiveViewer(
                                transformationController: _transformController,
                                minScale: 1.0,
                                maxScale: 5.0,
                                child: Image.file(
                                  file,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildErrorState(),
                                ),
                              ),
                            ),
                          )
                        : _buildErrorState(),
                  ),
                ),

                // Close button
                Positioned(
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),

                // Caption
                if (widget.caption != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black54,
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          widget.caption!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image, color: Colors.white38, size: 64),
        SizedBox(height: 16),
        Text(
          'Photo not found',
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      ],
    );
  }
}

/// Pushes the [FullscreenPhotoViewer] as a transparent overlay with
/// a fade transition (Hero handles the image animation).
void openPhotoViewer(
  BuildContext context, {
  required String photoPath,
  required String heroTag,
  String? caption,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => FullscreenPhotoViewer(
        photoPath: photoPath,
        heroTag: heroTag,
        caption: caption,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
