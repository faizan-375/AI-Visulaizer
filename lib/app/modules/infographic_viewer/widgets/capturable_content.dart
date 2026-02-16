import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class CapturableContent extends StatelessWidget {
  final String htmlContent;
  
  const CapturableContent({
    super.key,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: HtmlWidget(
          htmlContent,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          customStylesBuilder: (element) {
            if (element.localName == 'h1') {
              return {
                'font-size': '24px',
                'font-weight': 'bold',
                'color': '#2C3E50',
                'margin-bottom': '16px',
              };
            }
            if (element.localName == 'h2') {
              return {
                'font-size': '20px',
                'font-weight': 'bold',
                'color': '#34495E',
                'margin-bottom': '12px',
              };
            }
            if (element.localName == 'h3') {
              return {
                'font-size': '18px',
                'font-weight': 'bold',
                'color': '#34495E',
                'margin-bottom': '10px',
              };
            }
            if (element.localName == 'p') {
              return {
                'margin-bottom': '12px',
                'line-height': '1.6',
              };
            }
            return null;
          },
        ),
      ),
    );
  }
}