class DocumentItem {
  final String id;
  final String title;
  final String folder;
  String content;
  final String? tag;
  final bool isLarge;
  final String? filePath;

  DocumentItem({
    required this.id,
    required this.title,
    required this.folder,
    required this.content,
    this.tag,
    this.isLarge = false,
    this.filePath,
  });

  int get wordCount {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  int get lineCount => content.split('\n').length;

  String get estimatedReadingTime {
    final words = wordCount;
    final minutes = (words / 220).ceil().clamp(1, 999);
    return '$minutes min read';
  }

  String get approximateSizeStr {
    final bytes = content.length;
    if (isLarge || bytes > 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
}

class HeadingItem {
  final int level;
  final String text;
  final String id;
  final int index;

  HeadingItem({
    required this.level,
    required this.text,
    required this.id,
    this.index = 0,
  });
}

