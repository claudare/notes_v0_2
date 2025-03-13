sealed class ContentDiff {
  List<ContentDiffOp> ops;

  ContentDiff({required this.ops});

  ContentDiff.fromMap(Map<String, dynamic> map)
    : ops = List<ContentDiffOp>.from(
        map['ops'].map((op) => ContentDiffOp.fromMap(op)));

  Map<String, dynamic> toMap() => {
    'ops': ops.map((op) => op.toMap()).toList(),
  };

  @override
  String toString() => 'ContentDiff[ops: ${ops.join(", ")}]';
}

sealed class ContentDiffOp {
  static final Map<String, ContentDiffOp Function(Map<String, dynamic>)> _parsers = {
    ContentDiffPaste._type: ContentDiffPaste.fromMap,
    ContentDiffDelete._type: ContentDiffDelete.fromMap,
  };

  const ContentDiffOp();

  factory ContentDiffOp.fromMap(Map<String, dynamic> map) {
    final opType = map['_type'];

    if (_parsers.containsKey(opType)) {
      return _parsers[opType]!(map);
    }

    throw ArgumentError('Unknown diff op type: $opType');
  }

  Map<String, dynamic> toMap();
}

class ContentDiffPaste extends ContentDiffOp {
  final int line;
  final String content;

  ContentDiffPaste({required this.line, required this.content});

  static const String _type = 'paste';

  @override
  ContentDiffPaste.fromMap(Map<String, dynamic> map)
    : line = map['line'],
      content = map['content'];

  @override
  Map<String, dynamic> toMap() => {
    '_type': _type,
    'line': line,
    'content': content,
  };

  @override
  String toString() => 'Paste[line: $line, content: $content]';
}

class ContentDiffDelete extends ContentDiffOp {
  final int fromLine;
  final int lineCount;

  ContentDiffDelete({required this.fromLine, required this.lineCount});

  static const String _type = 'delete';

  @override
  ContentDiffDelete.fromMap(Map<String, dynamic> map)
    : fromLine = map['fromLine'],
      lineCount = map['lineCount'];

  @override
  Map<String, dynamic> toMap() => {
    '_type': _type,
    'fromLine': fromLine,
    'lineCount': lineCount,
  };

  @override
  String toString() => 'Delete[fromLine: $fromLine, lineCount: $lineCount]';
}
