import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class PDFService {
  static Future<String> generatePDFFromHTML(
    String prompt,
    String htmlContent,
  ) async {
    print('📄 PDF: Starting PDF generation from HTML...');
    print('📄 PDF: HTML content length: ${htmlContent.length} characters');

    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      _addTitlePage(pdf, prompt);

      // Parse HTML content
      final document = html_parser.parse(htmlContent);
      
      // Find all sections with class "section-16-9"
      final sections = document.querySelectorAll('.section-16-9');
      print('📄 PDF: Found ${sections.length} sections to process');

      if (sections.isEmpty) {
        // If no sections found, create a single page with the content
        _addContentPage(pdf, document.body?.text ?? 'No content available', 'Content');
      } else {
        // Process each section
        for (int i = 0; i < sections.length; i++) {
          final section = sections[i];
          final sectionTitle = _extractSectionTitle(section, i);
          final sectionContent = _extractSectionContent(section);
          
          print('📄 PDF: Processing section ${i + 1}: $sectionTitle');
          
          _addContentPage(pdf, sectionContent, sectionTitle);
        }
      }

      // Save PDF
      final pdfBytes = await pdf.save();
      print('📄 PDF: PDF generated successfully, size: ${pdfBytes.length} bytes');

      // Save to file
      final filePath = await _savePDFFile(pdfBytes, prompt);
      print('📄 PDF: PDF saved to: $filePath');

      return filePath;
    } catch (e) {
      print('📄 PDF: Error generating PDF: $e');
      rethrow;
    }
  }

  static Future<String> generatePDFFromScreenshot({
    required String prompt,
    required Uint8List screenshotBytes,
  }) async {
    try {
      print('📄 PDF: Starting PDF generation with ${screenshotBytes.length} bytes');
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Create image from screenshot bytes
      final image = pw.MemoryImage(screenshotBytes);
      
      // Add simple content page with screenshot only
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
                width: 550,
                height: 700,
              ),
            );
          },
        ),
      );
      
      // Save PDF
      final pdfBytes = await pdf.save();
      print('📄 PDF: Generated PDF with ${pdfBytes.length} bytes');
      
      final filePath = await _savePDFFile(pdfBytes, prompt);
      print('📄 PDF: Saved to $filePath');
      
      return filePath;
    } catch (e) {
      print('📄 PDF: Error generating PDF: $e');
      rethrow;
    }
  }

  static Future<String> generatePDFWithScreenshots(
    String prompt,
    Map<int, Uint8List> sectionScreenshots,
  ) async {
    print('📄 PDF: Starting PDF generation with screenshots...');
    print('📄 PDF: Processing ${sectionScreenshots.length} screenshots');

    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      _addTitlePage(pdf, prompt);

      // Add screenshot pages
      for (final entry in sectionScreenshots.entries) {
        final sectionIndex = entry.key;
        final screenshot = entry.value;
        
        print('📄 PDF: Processing section $sectionIndex with ${screenshot.length} bytes');
        
        try {
          // Convert Uint8List to PDF image
          final image = pw.MemoryImage(screenshot);
          
          // Add page with screenshot
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Section ${sectionIndex + 1}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
          
          print('📄 PDF: Successfully added section $sectionIndex to PDF');
        } catch (e) {
          print('📄 PDF: Error adding section $sectionIndex: $e');
          
          // Add error page
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Section ${sectionIndex + 1}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Error loading screenshot',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Screenshot size: ${screenshot.length} bytes',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }

      // Save PDF
      final pdfBytes = await pdf.save();
      print('📄 PDF: PDF generated successfully, size: ${pdfBytes.length} bytes');

      // Save to file
      final filePath = await _savePDFFile(pdfBytes, prompt);
      print('📄 PDF: PDF saved to: $filePath');

      return filePath;
    } catch (e) {
      print('📄 PDF: Error generating PDF: $e');
      rethrow;
    }
  }

  static String _extractSectionTitle(html_dom.Element section, int index) {
    // Try to find a heading (h1, h2, h3, etc.)
    final heading = section.querySelector('h1, h2, h3, h4, h5, h6');
    if (heading != null) {
      return heading.text.trim();
    }
    
    // Try to find a title attribute
    final title = section.attributes['title'];
    if (title != null && title.isNotEmpty) {
      return title;
    }
    
    // Fallback to section number
    return 'Section ${index + 1}';
  }

  static String _extractSectionContent(html_dom.Element section) {
    final buffer = StringBuffer();
    
    // Extract text content from all elements
    final elements = section.querySelectorAll('*');
    
    for (final element in elements) {
      final tagName = element.localName?.toLowerCase();
      final text = element.text.trim();
      
      if (text.isNotEmpty) {
        switch (tagName) {
          case 'h1':
            buffer.writeln('${text.toUpperCase()}\n');
            break;
          case 'h2':
            buffer.writeln('${text.toUpperCase()}\n');
            break;
          case 'h3':
            buffer.writeln('${text.toUpperCase()}\n');
            break;
          case 'p':
            buffer.writeln('$text\n');
            break;
          case 'li':
            buffer.writeln('• $text');
            break;
          case 'div':
            if (element.className.contains('statistic') || 
                element.className.contains('metric') ||
                element.className.contains('card')) {
              buffer.writeln('$text\n');
            }
            break;
          default:
            if (text.length > 10) { // Only add substantial text
              buffer.writeln('$text\n');
            }
        }
      }
    }
    
    final content = buffer.toString().trim();
    return content.isNotEmpty ? content : 'No content available';
  }

  static void _addContentPage(pw.Document pdf, String content, String title) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(
                child: pw.Text(
                  content,
                  style: pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _addTitlePage(pw.Document pdf, String prompt) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'AI Visualizer',
                style: const pw.TextStyle(
                  fontSize: 32,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Infographic Report',
                style: const pw.TextStyle(
                  fontSize: 24,
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Topic: $prompt',
                style: const pw.TextStyle(
                  fontSize: 18,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Generated with AI Visualizer',
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<String> _savePDFFile(Uint8List pdfBytes, String prompt) async {
    try {
      // Get app's documents directory (more reliable for sharing)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedPrompt = prompt.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final fileName = 'generated_presentation_${sanitizedPrompt}_$timestamp.pdf';
      final filePath = '${appDocDir.path}/$fileName';

      // Save PDF file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('📄 PDF: File saved to $filePath');
      return filePath;
    } catch (e) {
      print('📄 PDF: Error saving PDF file: $e');
      rethrow;
    }
  }
}
