import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MessageContent extends StatelessWidget {
  final String text;
  final bool enableMarkdown;
  final TextStyle? textStyle;

  const MessageContent({
    super.key,
    required this.text,
    required this.enableMarkdown,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableMarkdown) {
      return Text(text, style: textStyle);
    }

    final hasLatex = text.contains(r'$') || text.contains(r'\(') || text.contains(r'\[');
    if (!hasLatex) {
      return MarkdownBody(
        data: text,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: textStyle,
          code: textStyle?.copyWith(fontFamily: 'monospace', backgroundColor: Colors.grey.withValues(alpha: 0.1)),
        ),
        shrinkWrap: true,
      );
    }

    return _buildMixedContent(context);
  }

  Widget _buildMixedContent(BuildContext context) {
    final parts = _splitLatex(text);
    if (parts.isEmpty) {
      return Text(text, style: textStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: parts.map((part) {
        if (part.isLatex) {
          return _buildLatex(part.text);
        }
        if (part.text.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return MarkdownBody(
          data: part.text,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: textStyle,
            code: textStyle?.copyWith(fontFamily: 'monospace', backgroundColor: Colors.grey.withValues(alpha: 0.1)),
          ),
          shrinkWrap: true,
        );
      }).toList(),
    );
  }

  Widget _buildLatex(String latex) {
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Math.tex(
          latex,
          textStyle: textStyle,
          mathStyle: MathStyle.text,
        ),
      );
    } catch (_) {
      return Text('\$$latex\$', style: textStyle);
    }
  }

  List<_TextPart> _splitLatex(String text) {
    final parts = <_TextPart>[];
    final regex = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$|\\\[(.+?)\\\]|\\\((.+?)\\\)', dotAll: true);
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        parts.add(_TextPart(text.substring(lastEnd, match.start), false));
      }
      
      final latex = match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
      parts.add(_TextPart(latex, true));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      parts.add(_TextPart(text.substring(lastEnd), false));
    }

    return parts;
  }
}

class _TextPart {
  final String text;
  final bool isLatex;

  _TextPart(this.text, this.isLatex);
}
