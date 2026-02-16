import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PPTXService {
  static Future<String> generatePPTXFromScreenshot({
    required String prompt,
    required Uint8List screenshotBytes,
  }) async {
    try {
      print('🎯 PPTX: Starting presentation generation with ${screenshotBytes.length} bytes');
      
      // Create a PDF in presentation format (16:9 aspect ratio)
      final pdf = pw.Document();
      
      // Create image from screenshot bytes
      final image = pw.MemoryImage(screenshotBytes);
      
      // Add title slide
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    prompt,
                    style: const pw.TextStyle(fontSize: 28),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Generated with AI Visualizer',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      );
      
      // Add content slide with screenshot
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Container(
              width: 800,
              height: 550,
              child: pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              ),
            );
          },
        ),
      );
      
      // Save as PDF (presentation format)
      final pdfBytes = await pdf.save();
      print('🎯 PPTX: Generated presentation PDF with ${pdfBytes.length} bytes');
      
      final filePath = await _savePresentationFile(pdfBytes, prompt);
      print('🎯 PPTX: Saved to $filePath');
      
      return filePath;
    } catch (e) {
      print('🎯 PPTX: Error generating presentation: $e');
      rethrow;
    }
  }
  
  static Future<String> _savePresentationFile(Uint8List pdfBytes, String prompt) async {
    try {
      // Get app's documents directory (more reliable for sharing)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      // Create filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedPrompt = prompt.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final filename = 'generated_presentation_${sanitizedPrompt}_$timestamp.pdf';
      final filePath = '${appDocDir.path}/$filename';
      
      // Save PDF file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      return filePath;
    } catch (e) {
      print('🎯 PPTX: Error saving presentation file: $e');
      rethrow;
    }
  }
}