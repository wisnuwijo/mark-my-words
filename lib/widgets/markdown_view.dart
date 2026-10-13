import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import '../theme/linear_theme.dart';
import 'mermaid_widget.dart';

class LinearMarkdownView extends StatelessWidget {
  final String data;
  final bool isDark;
  final double fontSize;
  final ContentWidthMode widthMode;
  final ScrollController? scrollController;
  final HeadingKeyRegistry? headingRegistry;
  final Function(String taskText, bool isDone)? onTaskToggled;

  const LinearMarkdownView({
    super.key,
    required this.data,
    required this.isDark,
    required this.fontSize,
    required this.widthMode,
    this.scrollController,
    this.headingRegistry,
    this.onTaskToggled,
  });

  @override
  Widget build(BuildContext context) {
    headingRegistry?.reset();

    final textColor = isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;
    final secondaryTextColor = isDark
        ? LinearColors.darkTextSecondary
        : LinearColors.lightTextSecondary;
    final codeBg = isDark
        ? LinearColors.darkBgCode
        : LinearColors.lightBgCode;
    final borderColor = isDark
        ? LinearColors.darkBorderDefault
        : LinearColors.lightBorderDefault;

    final markdownStyle = MarkdownStyleSheet(
      p: GoogleFonts.inter(
        fontSize: fontSize,
        height: 1.68,
        color: textColor,
      ),
      h1: GoogleFonts.inter(
        fontSize: fontSize * 2.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.25,
        color: textColor,
      ),
      h2: GoogleFonts.inter(
        fontSize: fontSize * 1.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.35,
        color: textColor,
      ),
      h3: GoogleFonts.inter(
        fontSize: fontSize * 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.4,
        color: textColor,
      ),
      h4: GoogleFonts.inter(
        fontSize: fontSize * 1.1,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      blockquote: GoogleFonts.inter(
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
        color: secondaryTextColor,
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        border: const Border(
          left: BorderSide(color: LinearColors.accent, width: 3),
        ),
      ),
      code: GoogleFonts.jetBrainsMono(
        fontSize: fontSize * 0.88,
        color: LinearColors.cyan,
        backgroundColor: codeBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? LinearColors.darkBorderSubtle
                : LinearColors.lightBorderSubtle,
            width: 1,
          ),
        ),
      ),
      tableBody: GoogleFonts.inter(fontSize: fontSize * 0.9, color: textColor),
      tableHead: GoogleFonts.inter(
        fontSize: fontSize * 0.85,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: secondaryTextColor,
      ),
      tableBorder: TableBorder.all(
        color: isDark
            ? LinearColors.darkBorderSubtle
            : LinearColors.lightBorderSubtle,
        width: 1,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tableColumnWidth: const FlexColumnWidth(),
      listBullet: GoogleFonts.inter(color: LinearColors.accent),
    );

    return SingleChildScrollView(
      controller: scrollController,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: widthMode.maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Markdown(
            noScroll: true,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            data: data,
            selectable: true,
            styleSheet: markdownStyle,
            extensionSet: md.ExtensionSet.gitHubFlavored,
            builders: {
              'code': _LinearCodeElementBuilder(isDark: isDark),
              'h1': _HeadingElementBuilder(level: 1, isDark: isDark, fontSize: fontSize, registry: headingRegistry),
              'h2': _HeadingElementBuilder(level: 2, isDark: isDark, fontSize: fontSize, registry: headingRegistry),
              'h3': _HeadingElementBuilder(level: 3, isDark: isDark, fontSize: fontSize, registry: headingRegistry),
              'h4': _HeadingElementBuilder(level: 4, isDark: isDark, fontSize: fontSize, registry: headingRegistry),
              'h5': _HeadingElementBuilder(level: 5, isDark: isDark, fontSize: fontSize, registry: headingRegistry),
              'h6': _HeadingElementBuilder(level: 6, isDark: isDark, fontSize: fontSize, registry: headingRegistry),
            },
          ),
        ),
      ),
    );
  }
}

class HeadingKeyRegistry {
  final Map<String, GlobalKey> keys;
  final Map<String, int> _titleOccurrences = {};
  int _globalIndex = 0;

  HeadingKeyRegistry(this.keys);

  void reset() {
    _titleOccurrences.clear();
    _globalIndex = 0;
  }

  GlobalKey getOrCreateKey(String headingText) {
    final cleanText = headingText.replaceAll(RegExp(r'[*_`]'), '').trim();
    final normalized = cleanText.toLowerCase();
    final count = _titleOccurrences[normalized] ?? 0;
    _titleOccurrences[normalized] = count + 1;
    final id = 'heading_${normalized}_$count';
    final indexId = 'heading_idx_$_globalIndex';
    final simpleIndex = 'heading_$_globalIndex';
    _globalIndex++;

    final key = keys.putIfAbsent(id, () => GlobalKey());
    keys[indexId] = key;
    keys[simpleIndex] = key;
    return key;
  }
}

class _HeadingElementBuilder extends MarkdownElementBuilder {
  final int level;
  final bool isDark;
  final double fontSize;
  final HeadingKeyRegistry? registry;

  _HeadingElementBuilder({
    required this.level,
    required this.isDark,
    required this.fontSize,
    this.registry,
  });

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    return Text(text.text, style: preferredStyle);
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final rawText = element.textContent;
    final key = registry?.getOrCreateKey(rawText);

    final textColor = isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;

    final style = preferredStyle ?? _getFallbackHeadingStyle(level, textColor);

    final spans = element.children?.map((c) => _buildInlineSpan(c, style)).toList();
    final Widget headingChild = (spans != null && spans.isNotEmpty)
        ? Text.rich(TextSpan(style: style, children: spans))
        : Text(rawText, style: style);

    return Container(
      key: key,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      margin: _getHeadingMargin(level),
      child: headingChild,
    );
  }

  TextSpan _buildInlineSpan(md.Node node, TextStyle baseStyle) {
    if (node is md.Text) {
      return TextSpan(text: node.text, style: baseStyle);
    }
    if (node is md.Element) {
      if (node.tag == 'strong' || node.tag == 'b') {
        return TextSpan(
          text: node.textContent,
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        );
      }
      if (node.tag == 'em' || node.tag == 'i') {
        return TextSpan(
          text: node.textContent,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        );
      }
      if (node.tag == 'code') {
        return TextSpan(
          text: node.textContent,
          style: GoogleFonts.jetBrainsMono(
            fontSize: (baseStyle.fontSize ?? 14) * 0.88,
            color: LinearColors.cyan,
            backgroundColor: isDark ? LinearColors.darkBgCode : LinearColors.lightBgCode,
          ),
        );
      }
      return TextSpan(
        style: baseStyle,
        children: node.children?.map((c) => _buildInlineSpan(c, baseStyle)).toList(),
      );
    }
    return TextSpan(text: node.textContent, style: baseStyle);
  }

  EdgeInsets _getHeadingMargin(int level) {
    switch (level) {
      case 1:
        return const EdgeInsets.only(top: 28, bottom: 12);
      case 2:
        return const EdgeInsets.only(top: 22, bottom: 10);
      case 3:
        return const EdgeInsets.only(top: 16, bottom: 8);
      default:
        return const EdgeInsets.only(top: 12, bottom: 6);
    }
  }

  TextStyle _getFallbackHeadingStyle(int level, Color textColor) {
    switch (level) {
      case 1:
        return GoogleFonts.inter(
          fontSize: fontSize * 2.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.25,
          color: textColor,
        );
      case 2:
        return GoogleFonts.inter(
          fontSize: fontSize * 1.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          height: 1.35,
          color: textColor,
        );
      case 3:
        return GoogleFonts.inter(
          fontSize: fontSize * 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.4,
          color: textColor,
        );
      case 4:
        return GoogleFonts.inter(
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.w600,
          color: textColor,
        );
      default:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        );
    }
  }
}


class _LinearCodeElementBuilder extends MarkdownElementBuilder {
  final bool isDark;

  _LinearCodeElementBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final code = element.textContent;

    // Check if Mermaid Diagram block
    if (language.toLowerCase() == 'mermaid' ||
        code.trim().startsWith('flowchart') ||
        code.trim().startsWith('sequenceDiagram') ||
        code.trim().startsWith('stateDiagram') ||
        code.trim().startsWith('graph')) {
      return MermaidWidget(code: code, isDark: isDark);
    }

    // Standard Code Block with Line Numbers & Copy Button
    if (code.contains('\n')) {
      return _CodeBlockCard(
        code: code,
        language: language.isEmpty ? 'text' : language,
        isDark: isDark,
      );
    }

    // Inline Code
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? LinearColors.darkBgCode : LinearColors.lightBgCode,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? LinearColors.darkBorderSubtle
              : LinearColors.lightBorderSubtle,
        ),
      ),
      child: Text(
        code,
        style: GoogleFonts.jetBrainsMono(
          fontSize: (preferredStyle?.fontSize ?? 14) * 0.9,
          color: isDark ? const Color(0xFF79C0FF) : const Color(0xFF0969DA),
        ),
      ),
    );
  }
}

class _CodeBlockCard extends StatefulWidget {
  final String code;
  final String language;
  final bool isDark;

  const _CodeBlockCard({
    required this.code,
    required this.language,
    required this.isDark,
  });

  @override
  State<_CodeBlockCard> createState() => _CodeBlockCardState();
}

class _CodeBlockCardState extends State<_CodeBlockCard> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code.trim()));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? LinearColors.darkBorderDefault
        : LinearColors.lightBorderDefault;
    final headerBg = widget.isDark
        ? LinearColors.darkBgSurfaceElevated
        : LinearColors.lightBgSurfaceElevated;
    final codeBg = widget.isDark
        ? LinearColors.darkBgCode
        : LinearColors.lightBgCode;
    final lines = widget.code.trimRight().split('\n');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.code,
                        size: 14,
                        color: widget.isDark
                            ? LinearColors.darkTextTertiary
                            : LinearColors.lightTextTertiary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.language.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? LinearColors.darkTextSecondary
                                : LinearColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _copy,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.isDark
                            ? LinearColors.darkBorderSubtle
                            : LinearColors.lightBorderSubtle,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _copied ? 'Copied!' : 'Copy',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: widget.isDark
                            ? LinearColors.darkTextSecondary
                            : LinearColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code lines with line numbers
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < lines.length; i++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            color: widget.isDark
                                ? LinearColors.darkTextMuted
                                : LinearColors.lightTextMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SelectableText(
                          lines[i],
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            height: 1.5,
                            color: _getSyntaxColor(lines[i], widget.isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSyntaxColor(String line, bool isDark) {
    final trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('#')) {
      return isDark ? const Color(0xFF8B949E) : const Color(0xFF6E7781);
    }
    if (trimmed.startsWith('export') ||
        trimmed.startsWith('import') ||
        trimmed.startsWith('pub struct') ||
        trimmed.startsWith('impl') ||
        trimmed.startsWith('const') ||
        trimmed.startsWith('let') ||
        trimmed.startsWith('function')) {
      return isDark ? const Color(0xFFFF7B72) : const Color(0xFFCF222E);
    }
    return isDark ? LinearColors.darkTextPrimary : LinearColors.lightTextPrimary;
  }
}
