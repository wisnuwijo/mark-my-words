import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/linear_theme.dart';

class LinearLoaderLine extends StatefulWidget {
  final bool isLoading;

  const LinearLoaderLine({super.key, required this.isLoading});

  @override
  State<LinearLoaderLine> createState() => _LinearLoaderLineState();
}

class _LinearLoaderLineState extends State<LinearLoaderLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(LinearLoaderLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return const SizedBox(height: 2.5);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 2.5,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (_controller.value * 3.0), 0),
              end: Alignment(-0.5 + (_controller.value * 3.0), 0),
              colors: const [
                Colors.transparent,
                LinearColors.accent,
                LinearColors.cyan,
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

class DocumentLoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final String title;
  final String meta;
  final bool isDark;

  const DocumentLoadingOverlay({
    super.key,
    required this.isVisible,
    required this.title,
    required this.meta,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final cardBg = isDark
        ? LinearColors.darkBgSurfaceElevated
        : LinearColors.lightBgSurfaceElevated;
    final borderColor = isDark
        ? LinearColors.darkBorderHighlight
        : LinearColors.lightBorderHighlight;
    final textColor = isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;
    final metaColor = isDark
        ? LinearColors.darkTextSecondary
        : LinearColors.lightTextSecondary;

    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(LinearColors.accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: GoogleFonts.jetBrainsMono(
                          color: metaColor,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
