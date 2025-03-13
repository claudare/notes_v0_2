class TextDiff {
  final List<TextDiffOp> ops;

  const TextDiff({required this.ops});

  Map<String, dynamic> toMap() => {'ops': ops.map((op) => op.toMap()).toList()};

  factory TextDiff.fromMap(Map<String, dynamic> map) {
    final List<dynamic> opsList = map['ops'] as List<dynamic>;
    return TextDiff(
      ops:
          opsList
              .map((op) => TextDiffOp.fromMap(op as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  String toString() => 'TextDiff[ops: ${ops.join(", ")}]';
}

sealed class TextDiffOp {
  const TextDiffOp();

  T map<T>({
    required T Function(TextDiffOpPaste op) paste,
    required T Function(TextDiffOpDelete op) delete,
  }) {
    return switch (this) {
      TextDiffOpPaste() => paste(this as TextDiffOpPaste),
      TextDiffOpDelete() => delete(this as TextDiffOpDelete),
    };
  }

  Map<String, dynamic> toMap() => map(
    paste: (op) => {'_type': 'paste', 'line': op.line, 'content': op.content},
    delete:
        (op) => {
          '_type': 'delete',
          'fromLine': op.fromLine,
          'lineCount': op.lineCount,
        },
  );

  static TextDiffOp fromMap(Map<String, dynamic> map) {
    return switch (map['_type']) {
      'paste' => TextDiffOpPaste(
        line: map['line'] as int,
        content: map['content'] as String,
      ),
      'delete' => TextDiffOpDelete(
        fromLine: map['fromLine'] as int,
        lineCount: map['lineCount'] as int,
      ),
      _ => throw ArgumentError('Unknown diff op type: ${map['_type']}'),
    };
  }
}

final class TextDiffOpPaste extends TextDiffOp {
  final int line;
  final String content;

  const TextDiffOpPaste({required this.line, required this.content});

  @override
  String toString() => 'Paste[line: $line, content: $content]';
}

final class TextDiffOpDelete extends TextDiffOp {
  final int fromLine;
  final int lineCount;

  const TextDiffOpDelete({required this.fromLine, required this.lineCount});

  @override
  String toString() => 'Delete[fromLine: $fromLine, lineCount: $lineCount]';
}
