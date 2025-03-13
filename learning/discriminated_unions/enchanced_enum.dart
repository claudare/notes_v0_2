enum ContentDiffOp {
  paste(type: 'paste'),
  delete(type: 'delete');

  final String type;
  const ContentDiffOp({required this.type});

  factory ContentDiffOp.fromMap(Map<String, dynamic> map) {
    return switch (map['type']) {
      'paste' => paste,
      'delete' => delete,
      _ => throw ArgumentError('Unknown type: ${map['type']}'),
    };
  }
}

class ContentDiff {
  final ContentDiffOp op;
  final int line;
  final String? content; // null for delete
  final int? lineCount; // null for paste

  const ContentDiff.paste({required this.line, required this.content})
    : op = ContentDiffOp.paste,
      lineCount = null;

  const ContentDiff.delete({required this.line, required this.lineCount})
    : op = ContentDiffOp.delete,
      content = null;
}
