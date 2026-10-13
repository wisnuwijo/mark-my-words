import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/linear_theme.dart';

class CommandPaletteAction {
  final String id;
  final String title;
  final String? group;
  final String? shortcut;
  final IconData icon;
  final VoidCallback onSelect;

  CommandPaletteAction({
    required this.id,
    required this.title,
    this.group,
    this.shortcut,
    required this.icon,
    required this.onSelect,
  });
}

class CommandPaletteDialog extends StatefulWidget {
  final List<CommandPaletteAction> actions;
  final bool isDark;

  const CommandPaletteDialog({
    super.key,
    required this.actions,
    required this.isDark,
  });

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  int _selectedIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase();
        _selectedIndex = 0;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  List<CommandPaletteAction> get _filteredActions {
    if (_query.isEmpty) return widget.actions;
    return widget.actions.where((action) {
      return action.title.toLowerCase().contains(_query) ||
          (action.group?.toLowerCase().contains(_query) ?? false);
    }).toList();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final filtered = _filteredActions;
    if (filtered.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % filtered.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < filtered.length) {
        Navigator.of(context).pop();
        filtered[_selectedIndex].onSelect();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredActions;
    final dialogBg = widget.isDark
        ? LinearColors.darkBgSurfaceElevated
        : LinearColors.lightBgSurfaceElevated;
    final borderColor = widget.isDark
        ? LinearColors.darkBorderHighlight
        : LinearColors.lightBorderHighlight;
    final textColor = widget.isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleKey,
        child: Center(
          child: Container(
            width: 580,
            margin: const EdgeInsets.only(bottom: 120),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Search Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDark
                          ? LinearColors.darkBorderSubtle
                          : LinearColors.lightBorderSubtle,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20,
                      color: widget.isDark
                          ? LinearColors.darkTextTertiary
                          : LinearColors.lightTextTertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a command or search documents...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 15,
                            color: widget.isDark
                                ? LinearColors.darkTextTertiary
                                : LinearColors.lightTextTertiary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    _buildShortcutBadge('ESC'),
                  ],
                ),
              ),

              // Results List
              SizedBox(
                height: filtered.isEmpty
                    ? 80
                    : (filtered.length * 44.0 + 16.0).clamp(60.0, 320.0),
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'No matching commands found',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: widget.isDark
                                  ? LinearColors.darkTextTertiary
                                  : LinearColors.lightTextTertiary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemBuilder: (context, index) {
                          final action = filtered[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              action.onSelect();
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (widget.isDark
                                        ? LinearColors.darkSurfaceActive
                                        : LinearColors.lightSurfaceActive)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          action.icon,
                                          size: 16,
                                          color: isSelected
                                              ? LinearColors.accentHover
                                              : (widget.isDark
                                                  ? LinearColors.darkTextSecondary
                                                  : LinearColors.lightTextSecondary),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            action.title,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? textColor
                                                  : (widget.isDark
                                                      ? LinearColors.darkTextSecondary
                                                      : LinearColors.lightTextSecondary),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (action.shortcut != null) ...[
                                    const SizedBox(width: 8),
                                    _buildShortcutBadge(action.shortcut!),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? LinearColors.darkBgSurface
                      : LinearColors.lightBgSurface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(11)),
                  border: Border(
                    top: BorderSide(
                      color: widget.isDark
                          ? LinearColors.darkBorderSubtle
                          : LinearColors.lightBorderSubtle,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Navigate with ',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: widget.isDark
                                    ? LinearColors.darkTextTertiary
                                    : LinearColors.lightTextTertiary)),
                        _buildShortcutBadge('↑'),
                        const SizedBox(width: 3),
                        _buildShortcutBadge('↓'),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Select with ',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: widget.isDark
                                    ? LinearColors.darkTextTertiary
                                    : LinearColors.lightTextTertiary)),
                        _buildShortcutBadge('↵'),
                      ],
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildShortcutBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isDark
            ? LinearColors.darkBgKbd
            : LinearColors.lightBgKbd,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isDark
              ? LinearColors.darkBorderDefault
              : LinearColors.lightBorderDefault,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: widget.isDark
              ? LinearColors.darkTextSecondary
              : LinearColors.lightTextSecondary,
        ),
      ),
    );
  }
}
