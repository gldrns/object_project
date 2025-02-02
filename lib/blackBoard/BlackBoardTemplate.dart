import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'package:flutter/widgets.dart';

class BlackboardTemplate {
  final XmlDocument _svg;

  BlackboardTemplate._internal(this._svg,);

  factory BlackboardTemplate.fromSvgString(String src) {
    return BlackboardTemplate._internal(XmlDocument.parse(src));
  }

  // Index -> text field spec, sorted by key
  Map<int, BlackboardField> findTextFields() {
    Map<int, BlackboardField> textFields = {};

    for (final element in _svg.xpath('//text[@class="textfield"]')) {
      final indexStr = element.getAttribute('data-index');
      if (indexStr == null) continue;
      final index = int.parse(indexStr);

      final tspans = element.findAllElements('tspan');
      String combinedText = tspans.map((tspan) => tspan.text).join('\n');

      final label = element.getAttribute('data-label');
      if (label == null) continue;
      final defaultText = combinedText;
      final necessary = (element.getAttribute('data-required') == 'true');
      final autofill = element.getAttribute('data-autofill');
      final maxLength = int.parse(element.getAttribute('data-max-length') ?? '50');
      final multiline = (element.getAttribute('data-multiline') == 'true');

      if (autofill != null && autofill.startsWith('[') && autofill.endsWith(']')) {
        element.setAttribute('fill', '#D3AD24');
      }

      textFields[index] = BlackboardField(
          label, defaultText, necessary, maxLength, multiline, autofill
      );
    }
    // Sort by key
    return SplayTreeMap.from(textFields, (a, b) => a.compareTo(b));
  }

  double calculateTextWidth({
    required String text,
    required TextStyle style,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  String fillTextFields(
      Map<int, String> input, {
        String? svgContent,
        bool keepPlaceholders = false,
        bool ignoreRequirements = false,
        required List<int> fontSize,
        int? highlightedIndex,
        String highlightColor = '#00683700',
        String? strokeColor,
        String backgroundColor = "#006837",
        bool haveDataIndex = false,
        List<double>? widthList,
        List<double>? heightList,
        String ? horizontal,
        String ? vertical
      }) {
    final svgCopy = _svg.copy();
    final fields = svgCopy.xpath('//text[@class="textfield"]');
    final rectElements = svgCopy.xpath('//rect');

    if (strokeColor != null) {
      if (rectElements.isNotEmpty) {
        rectElements.first.setAttribute('fill', backgroundColor);
      }

      for (final element in rectElements) {
        if (element.getAttribute('data-index') == null) {
          element.setAttribute('stroke', strokeColor);
        }
      }

      final lineElements = svgCopy.xpath('//line');
      for (final element in lineElements) {
        element.setAttribute('stroke', strokeColor);
      }
    }

    for (final element in fields) {
      final indexStr = element.getAttribute('data-index');
      if (indexStr == null) continue;
      final index = int.parse(indexStr);

      int innerIndex = int.parse(indexStr);

      if (innerIndex > 0) {
        innerIndex -= 1;
      }

      final text = input[index];

      if (text == null && element.innerText.isNotEmpty) {
        continue; // Keep default value
      }

      if (text == null || text.isEmpty) {
        if (element.getAttribute('data-required') == 'true' && !ignoreRequirements) {
          throw FormatException(
            "Field #$index is required, but not specified",
          );
        }

        if (keepPlaceholders) {
          element.innerText = element.getAttribute('data-label') ?? '';
          element.setAttribute('opacity', '0.5');
        } else {
          element.innerText = '';
        }
        continue;
      }


      final lines = text.split('\n').where((line) => line.isNotEmpty).toList();
      final linesInclude = text.split('\n');
      final multiline = element.getAttribute('data-multiline') == 'true';
      // var currentFontSize = fontSize[index];

      double parseWidth(String widthStr) {
        return double.tryParse(widthStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      }

      double parseHeight(String heightStr) {
        return double.tryParse(heightStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      }

      double calculateTextWidth(String text, int fontSize) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: TextStyle(fontSize: fontSize.toDouble())),
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 5, maxWidth: 100);

        textPainter.layout();
        return textPainter.size.width;
      }


      double calculateTextHeight(String text, int fontSize) {
        return linesInclude.length * fontSize * 1.5;
      }

      final availableWidth = widthList != null ? widthList[innerIndex] : double.infinity;
      final availableHeight = heightList != null ? heightList[innerIndex] : double.infinity;

      while (calculateTextHeight(text, fontSize[index]) > availableHeight && fontSize[index] > 5) {
        fontSize[index]--;
      }

      for (var line in text.split('\n').where((line) => line.isNotEmpty)) {
        while (calculateTextWidth(line, fontSize[index]) > availableWidth && fontSize[index] > 5) {
          fontSize[index]--;
        }
      }

      element.setAttribute('font-size', fontSize[index].toString());

      if (strokeColor != null) {
        element.setAttribute('fill', strokeColor);
      }

      element.innerText = '';

      var lineHeight = fontSize[index] * 1.5;

      text.split('\n').forEachIndexed((lineIndex, line) {
        final firstLineOffset = (multiline ? 0 : (1 - text.split('\n').length)) * lineHeight / 2.0;
        var y = firstLineOffset + lineIndex * lineHeight;
        var x = 0.0;

        if (horizontal != null && widthList != null && multiline) {
          switch (horizontal) {
            case "center":
              x = (calculateTextWidth(line, fontSize[index])) * 1.1 > widthList[innerIndex]? 0.0 :
              widthList[innerIndex]/2 - (calculateTextWidth(line, fontSize[index]))/1.9;
              break;
            case "end":
              x = (calculateTextWidth(line, fontSize[index])) * 1.1 > widthList[innerIndex] ? 0.0 :
              widthList[innerIndex] - (calculateTextWidth(line, fontSize[index]) * 1.1);
              break;
            default:
              x = 0.0;
              break;
          }
        }

        if (vertical != null && heightList != null && multiline) {
          final totalTextHeight = lineHeight * linesInclude.length;
          final availableHeight = heightList[innerIndex];

          switch (vertical) {
            case "center":
              y = (availableHeight - totalTextHeight) / 2 + lineIndex * lineHeight;
              break;

            case "bottom":
              y = availableHeight - totalTextHeight + lineIndex * lineHeight;
              break;

            default:
              y = firstLineOffset + lineIndex * lineHeight;
              break;
          }
        }

        final tspanElement = XmlElement(XmlName('tspan'), [
          XmlAttribute(XmlName('x'), x.toString()),
          XmlAttribute(XmlName('y'), multiline ? y.toString() : y.toString()),
        ], [
          XmlText(line),
        ]);

        element.children.add(tspanElement);
      });


      final selectedIndex = int.parse(indexStr);

      if (highlightedIndex != null
          && selectedIndex == highlightedIndex + 1
          && !haveDataIndex && widthList != null && heightList != null
      ) {
        final parent = element.parent;

        final rectElement = XmlElement(XmlName('rect'), [
          XmlAttribute(XmlName('x'), '-5'),
          XmlAttribute(XmlName('y'), multiline ? '-55' : '-45'),
          XmlAttribute(XmlName('width'), widthList[innerIndex].toString()),
          XmlAttribute(XmlName('height'), heightList[innerIndex].toString()),
          XmlAttribute(XmlName('fill'), highlightColor),
          XmlAttribute(XmlName('data-index'), index.toString()),
          XmlAttribute(XmlName('display'), 'block'),
          XmlAttribute(XmlName('stroke'), '#FF0000'),
          XmlAttribute(XmlName('stroke-width'), '4'),
        ]);

        parent?.children.insert(
          parent.children.indexOf(element),
          rectElement,
        );
      }

      for (var rect in rectElements) {
        final dataIndex = rect.getAttribute('data-index');
        if (highlightedIndex != null && dataIndex != null
            && int.parse(dataIndex) == highlightedIndex + 1
        ) {
          rect.setAttribute('display',"block");
          rect.setAttribute("stroke", "#FF0000");
        }
      }
    }

    return svgCopy.toXmlString();
  }

}

class BlackboardField {
  final String label;
  final String defaultValue;
  final bool necessary;
  final int maxLength;
  final bool multiline;
  final String? autofill;

  BlackboardField(
    this.label, this.defaultValue, this.necessary,
    this.maxLength, this.multiline, this.autofill
    );
}
