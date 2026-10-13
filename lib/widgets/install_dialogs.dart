import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/system_service.dart';
import '../theme/linear_theme.dart';

/// Modal dialog prompting the user to install MarkMyWord into /Applications
class MoveToApplicationsDialog extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onMoved;

  const MoveToApplicationsDialog({
    super.key,
    required this.isDark,
    this.onMoved,
  });

  static Future<void> show(BuildContext context, {required bool isDark}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => MoveToApplicationsDialog(isDark: isDark),
    );
  }

  @override
  State<MoveToApplicationsDialog> createState() => _MoveToApplicationsDialogState();
}

class _MoveToApplicationsDialogState extends State<MoveToApplicationsDialog> {
  bool _isMoving = false;
  String? _errorMessage;
  bool _dontAskAgain = false;
  bool _isDragging = false;
  bool _isTargetHovered = false;
  bool _hasDropped = false;

  Future<void> _handleMove() async {
    setState(() {
      _isMoving = true;
      _errorMessage = null;
    });

    try {
      final success = await SystemService.moveToApplicationsFolder();
      if (!success && mounted) {
        setState(() {
          _isMoving = false;
          _errorMessage =
              'Could not automatically move the app. You can drag MarkMyWord into Applications in Finder.';
        });
      } else {
        widget.onMoved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMoving = false;
          _errorMessage = 'Failed to move: $e';
        });
      }
    }
  }

  Future<void> _handleOpenApplications() async {
    await SystemService.openApplicationsFolder();
  }

  Future<void> _handleDismiss() async {
    if (_dontAskAgain) {
      await SystemService.setDontPromptMoveToApplications(true);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgSurface = widget.isDark
        ? LinearColors.darkBgSurfaceElevated
        : LinearColors.lightBgSurfaceElevated;
    final borderSubtle = widget.isDark
        ? LinearColors.darkBorderSubtle
        : LinearColors.lightBorderSubtle;
    final textPrimary = widget.isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? LinearColors.darkTextSecondary
        : LinearColors.lightTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.6 : 0.25),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with App Badge
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [LinearColors.accent, LinearColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: LinearColors.accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'M',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Install MarkMyWord to Applications',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'macOS Installation & System Setup',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: textSecondary,
                  splashRadius: 18,
                  onPressed: _handleDismiss,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Installation drag visual representation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? LinearColors.darkBgSurface
                    : LinearColors.lightBgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isTargetHovered
                      ? LinearColors.accent.withValues(alpha: 0.6)
                      : borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  // Source: MarkMyWord App (Draggable)
                  Expanded(
                    child: Draggable<String>(
                      data: 'MarkMyWord.app',
                      onDragStarted: () {
                        setState(() => _isDragging = true);
                      },
                      onDragEnd: (_) {
                        setState(() {
                          _isDragging = false;
                          _isTargetHovered = false;
                        });
                      },
                      onDraggableCanceled: (velocity, offset) {
                        setState(() {
                          _isDragging = false;
                          _isTargetHovered = false;
                        });
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.05,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.isDark
                                  ? LinearColors.darkBgSurfaceElevated
                                  : LinearColors.lightBgSurfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: LinearColors.accent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: LinearColors.accent.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: _buildSourceItem(
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isFloating: true,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.25,
                        child: _buildSourceItem(
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isPlaceholder: true,
                        ),
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Tooltip(
                          message: 'Drag into Applications to install',
                          child: _buildSourceItem(
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Drag indicator with arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isDragging || _isTargetHovered
                                ? LinearColors.accent.withValues(alpha: 0.25)
                                : LinearColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isDragging || _isTargetHovered
                                  ? LinearColors.accentHover
                                  : LinearColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _isTargetHovered
                                ? 'Release to install!'
                                : (_isDragging ? 'Drop in folder' : 'Drag to install'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isTargetHovered
                                  ? Colors.white
                                  : LinearColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isDragging ? 32 : 28,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _isTargetHovered
                                        ? LinearColors.cyan
                                        : LinearColors.accent,
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: _isTargetHovered
                                  ? LinearColors.cyan
                                  : LinearColors.accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Destination: Applications Folder (DragTarget)
                  Expanded(
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (details) {
                        setState(() => _isTargetHovered = true);
                        return true;
                      },
                      onLeave: (_) {
                        setState(() => _isTargetHovered = false);
                      },
                      onAcceptWithDetails: (details) {
                        setState(() {
                          _isTargetHovered = false;
                          _hasDropped = true;
                        });
                        _handleMove();
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty || _isTargetHovered;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _isMoving ? null : _handleMove,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? LinearColors.accent.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isHovered
                                      ? LinearColors.accent
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: _buildTargetItem(
                                textPrimary: isHovered ? LinearColors.accentHover : textPrimary,
                                textSecondary: textSecondary,
                                isHovered: isHovered,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description text
            Text(
              'MarkMyWord is currently running from an external disk image or downloads folder. '
              'Moving it to your Applications folder ensures proper system permissions, '
              'LaunchServices registration, and instant startup.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.5,
                color: textSecondary,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // "Don't ask again" Checkbox
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _dontAskAgain,
                    activeColor: LinearColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() => _dontAskAgain = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _dontAskAgain = !_dontAskAgain);
                  },
                  child: Text(
                    "Don't ask again for this version",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 10,
              children: [
                // Secondary: Reveal / Open Applications
                OutlinedButton.icon(
                  onPressed: _handleOpenApplications,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: borderSubtle),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open, size: 14),
                  label: Text(
                    'Open Finder',
                    style: GoogleFonts.inter(fontSize: 11.5),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Secondary: Dismiss
                    TextButton(
                      onPressed: _handleDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                      ),
                      child: Text(
                        "Don't Move",
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Primary: 1-Click Move to Applications
                    ElevatedButton(
                      onPressed: _isMoving ? null : _handleMove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LinearColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _isMoving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Moving...',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Move to Applications',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem({
    required Color textPrimary,
    required Color textSecondary,
    bool isFloating = false,
    bool isPlaceholder = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LinearColors.accent, LinearColors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isFloating
                ? [
                    BoxShadow(
                      color: LinearColors.accent.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: LinearColors.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            'M',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MarkMyWord.app',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isPlaceholder ? 'Drop in folder' : 'Drag me',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isPlaceholder ? LinearColors.accent : textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetItem({
    required Color textPrimary,
    required Color textSecondary,
    bool isHovered = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isHovered ? 52 : 48,
          height: isHovered ? 52 : 48,
          decoration: BoxDecoration(
            color: isHovered
                ? LinearColors.accent.withValues(alpha: 0.25)
                : (widget.isDark
                    ? LinearColors.darkSurfaceHover
                    : LinearColors.lightSurfaceHover),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? LinearColors.accent
                  : LinearColors.cyan.withValues(alpha: 0.5),
              width: isHovered ? 2.0 : 1.5,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: LinearColors.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            _hasDropped ? Icons.check_circle : Icons.folder_special,
            size: isHovered ? 30 : 28,
            color: isHovered ? Colors.white : LinearColors.cyan,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Applications',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isHovered ? 'Release to install' : '/Applications',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isHovered ? FontWeight.w600 : FontWeight.w400,
            color: isHovered ? LinearColors.accent : textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Modal dialog prompting the user to set MarkMyWord as default viewer for Markdown files
class DefaultViewerDialog extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onCompleted;

  const DefaultViewerDialog({
    super.key,
    required this.isDark,
    this.onCompleted,
  });

  static Future<void> show(BuildContext context, {required bool isDark}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => DefaultViewerDialog(isDark: isDark),
    );
  }

  @override
  State<DefaultViewerDialog> createState() => _DefaultViewerDialogState();
}

class _DefaultViewerDialogState extends State<DefaultViewerDialog> {
  bool _isSetting = false;
  bool _dontAskAgain = false;
  String? _statusMessage;
  bool _isSuccess = false;
  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSetDefault() async {
    setState(() {
      _isSetting = true;
      _statusMessage = null;
    });

    try {
      final success = await SystemService.setDefaultMarkdownViewer();
      if (mounted) {
        setState(() {
          _isSetting = false;
          _isSuccess = success;
          _statusMessage = success
              ? 'MarkMyWord is now your default Markdown reader!'
              : 'Could not update system defaults automatically. Please check macOS System Settings.';
        });

        if (success) {
          _closeTimer = Timer(const Duration(milliseconds: 1400), () {
            if (mounted) {
              widget.onCompleted?.call();
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSetting = false;
          _isSuccess = false;
          _statusMessage = 'Failed: $e';
        });
      }
    }
  }

  Future<void> _handleDismiss() async {
    if (_dontAskAgain) {
      await SystemService.setDontPromptDefaultViewer(true);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgSurface = widget.isDark
        ? LinearColors.darkBgSurfaceElevated
        : LinearColors.lightBgSurfaceElevated;
    final borderSubtle = widget.isDark
        ? LinearColors.darkBorderSubtle
        : LinearColors.lightBorderSubtle;
    final textPrimary = widget.isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;
    final textSecondary = widget.isDark
        ? LinearColors.darkTextSecondary
        : LinearColors.lightTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.6 : 0.25),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LinearColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LinearColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: LinearColors.accentHover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set as Default Markdown Reader',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Open .md and .markdown documents in MarkMyWord',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: textSecondary,
                  splashRadius: 18,
                  onPressed: _handleDismiss,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Card preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? LinearColors.darkBgSurface
                    : LinearColors.lightBgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? LinearColors.darkBgKbd
                          : LinearColors.lightBgKbd,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Text(
                      '.md',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: LinearColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Markdown Document Association',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Double-clicking any .md file in Finder will immediately launch MarkMyWord.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? LinearColors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isSuccess
                        ? LinearColors.green.withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle : Icons.info_outline,
                      size: 16,
                      color:
                          _isSuccess ? LinearColors.green : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _isSuccess
                              ? LinearColors.green
                              : Colors.orangeAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Don't ask again Checkbox
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _dontAskAgain,
                    activeColor: LinearColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() => _dontAskAgain = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _dontAskAgain = !_dontAskAgain);
                  },
                  child: Text(
                    "Don't ask again",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _handleDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  child: Text(
                    'Not Now',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSetting || _isSuccess ? null : _handleSetDefault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LinearColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: _isSetting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Setting Default...',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Set as Default',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
