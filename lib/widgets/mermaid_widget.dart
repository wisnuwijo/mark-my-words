import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/linear_theme.dart';

class MermaidWidget extends StatefulWidget {
  final String code;
  final bool isDark;

  const MermaidWidget({
    super.key,
    required this.code,
    required this.isDark,
  });

  @override
  State<MermaidWidget> createState() => _MermaidWidgetState();
}

class _MermaidWidgetState extends State<MermaidWidget> {
  bool _showSource = false;
  bool _copied = false;

  void _copyCode() {
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
    final bodyBg = widget.isDark
        ? LinearColors.darkBgSurface
        : LinearColors.lightBgSurface;
    final textColor = widget.isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      const Icon(
                        Icons.schema_outlined,
                        size: 15,
                        color: LinearColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'MERMAID DIAGRAM',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: LinearColors.accentHover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn('Diagram', !_showSource, () {
                      setState(() => _showSource = false);
                    }),
                    const SizedBox(width: 4),
                    _buildToggleBtn('Source', _showSource, () {
                      setState(() => _showSource = true);
                    }),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _copyCode,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
              ],
            ),
          ),

          // Body: Diagram Canvas or Raw Code
          if (_showSource)
            Container(
              padding: const EdgeInsets.all(16),
              color: widget.isDark
                  ? LinearColors.darkBgCode
                  : LinearColors.lightBgCode,
              child: SelectableText(
                widget.code.trim(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildMermaidDiagram(widget.code.trim()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? (widget.isDark
                  ? LinearColors.darkSurfaceActive
                  : LinearColors.lightSurfaceActive)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? LinearColors.accent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active
                ? LinearColors.accentHover
                : (widget.isDark
                    ? LinearColors.darkTextTertiary
                    : LinearColors.lightTextTertiary),
          ),
        ),
      ),
    );
  }

  Widget _buildMermaidDiagram(String raw) {
    final lower = raw.toLowerCase();

    if (lower.contains('sequence')) {
      return _buildSequenceDiagram();
    } else if (lower.contains('statediagram')) {
      return _buildStateDiagram();
    } else if (lower.contains('subgraph') || lower.contains('flowchart td')) {
      return _buildClusterFlowchart();
    } else {
      return _buildStandardFlowchart();
    }
  }

  // Diagram 1: Flowchart LR
  Widget _buildStandardFlowchart() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNode('Local Disk (.md)', icon: Icons.description_outlined),
        _buildArrow('stream'),
        _buildNode('Memory Buffer', icon: Icons.memory),
        _buildArrow('parse'),
        _buildDiamond('AST Engine'),
        _buildArrow('render'),
        _buildNode('120fps Canvas', isAccent: true, icon: Icons.desktop_mac),
      ],
    );
  }

  // Diagram 2: Sequence Diagram
  Widget _buildSequenceDiagram() {
    final textColor = widget.isDark
        ? LinearColors.darkTextPrimary
        : LinearColors.lightTextPrimary;
    final mutedColor = widget.isDark
        ? LinearColors.darkTextSecondary
        : LinearColors.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActor('Mac User', Icons.person_outline),
            const SizedBox(width: 80),
            _buildActor('macOS Shell', Icons.laptop_mac),
            const SizedBox(width: 80),
            _buildActor('MMW Engine', Icons.speed),
            const SizedBox(width: 80),
            _buildActor('Linear Canvas', Icons.draw_outlined),
          ],
        ),
        const SizedBox(height: 20),
        _buildSeqStep('1. Open file dialog (⌘O)', 0, 1, mutedColor),
        const SizedBox(height: 12),
        _buildSeqStep('2. Stream zero-copy mmap', 1, 2, mutedColor),
        const SizedBox(height: 12),
        _buildSeqStep('3. Compile AST & Mermaid tokens', 2, 2, mutedColor),
        const SizedBox(height: 12),
        _buildSeqStep('4. Hardware accelerated blit (< 16ms)', 2, 3, textColor,
            isAccent: true),
      ],
    );
  }

  Widget _buildSeqStep(String label, int from, int to, Color color,
      {bool isAccent = false}) {
    return Container(
      width: 460,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAccent
            ? LinearColors.accent.withValues(alpha: 0.12)
            : (widget.isDark
                ? LinearColors.darkBgCode
                : LinearColors.lightBgCode),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAccent
              ? LinearColors.accent.withValues(alpha: 0.4)
              : (widget.isDark
                  ? LinearColors.darkBorderSubtle
                  : LinearColors.lightBorderSubtle),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAccent ? Icons.flash_on : Icons.arrow_right_alt,
            size: 16,
            color: isAccent ? LinearColors.accent : color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isAccent ? FontWeight.w600 : FontWeight.w400,
                color: isAccent ? LinearColors.accentHover : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActor(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? LinearColors.darkBgSurfaceElevated
            : LinearColors.lightBgSurfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isDark
              ? LinearColors.darkBorderDefault
              : LinearColors.lightBorderDefault,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LinearColors.accent),
          const SizedBox(width: 6),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.isDark
                  ? LinearColors.darkTextPrimary
                  : LinearColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Diagram 3: State Diagram
  Widget _buildStateDiagram() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatePill('Observed', isStart: true),
        _buildArrow('diff'),
        _buildStatePill('Reconciling'),
        _buildArrow('health'),
        _buildStatePill('InSync (Ready)', isAccent: true),
      ],
    );
  }

  Widget _buildStatePill(String name,
      {bool isStart = false, bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isAccent
            ? LinearColors.accent.withValues(alpha: 0.18)
            : (widget.isDark
                ? LinearColors.darkBgSurfaceElevated
                : LinearColors.lightBgSurfaceElevated),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAccent
              ? LinearColors.accent
              : (widget.isDark
                  ? LinearColors.darkBorderDefault
                  : LinearColors.lightBorderDefault),
          width: 1.5,
        ),
      ),
      child: Text(
        name,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isAccent ? FontWeight.w600 : FontWeight.w500,
          color: isAccent
              ? LinearColors.accentHover
              : (widget.isDark
                  ? LinearColors.darkTextPrimary
                  : LinearColors.lightTextPrimary),
        ),
      ),
    );
  }

  // Diagram 4: Multi-node Cluster Flowchart
  Widget _buildClusterFlowchart() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildClusterBox('Control Plane (Master)', [
              'kube-apiserver',
              'etcd Raft Ring',
              'kube-scheduler',
            ]),
            const SizedBox(width: 40),
            const Icon(Icons.swap_horiz, size: 28, color: LinearColors.accent),
            const SizedBox(width: 40),
            _buildClusterBox('Worker Nodes (Pool)', [
              'kubelet agent',
              'Container Runtime',
              'eBPF Cilium Mesh',
            ]),
          ],
        ),
      ],
    );
  }

  Widget _buildClusterBox(String title, List<String> items) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? LinearColors.darkBgCode
            : LinearColors.lightBgCode,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark
              ? LinearColors.darkBorderHighlight
              : LinearColors.lightBorderHighlight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: LinearColors.accentHover,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: LinearColors.cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: widget.isDark
                          ? LinearColors.darkTextPrimary
                          : LinearColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNode(String text,
      {bool isAccent = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAccent
            ? LinearColors.accent.withValues(alpha: 0.18)
            : (widget.isDark
                ? LinearColors.darkBgSurfaceElevated
                : LinearColors.lightBgSurfaceElevated),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAccent
              ? LinearColors.accent
              : (widget.isDark
                  ? LinearColors.darkBorderDefault
                  : LinearColors.lightBorderDefault),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isAccent ? LinearColors.accent : LinearColors.cyan),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isAccent ? FontWeight.w600 : FontWeight.w500,
              color: isAccent
                  ? LinearColors.accentHover
                  : (widget.isDark
                      ? LinearColors.darkTextPrimary
                      : LinearColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiamond(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LinearColors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LinearColors.purple, width: 1.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LinearColors.purple,
        ),
      ),
    );
  }

  Widget _buildArrow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: widget.isDark
                  ? LinearColors.darkTextTertiary
                  : LinearColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 2),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                child: Divider(
                  color: LinearColors.accent,
                  thickness: 1.5,
                ),
              ),
              Icon(
                Icons.arrow_right,
                size: 16,
                color: LinearColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
