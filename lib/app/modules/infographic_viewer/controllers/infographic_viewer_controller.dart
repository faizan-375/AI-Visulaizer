import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import '../../../data/models/infographic_model.dart';

class InfographicViewerController extends GetxController {
  late InfographicModel infographic;
  InAppWebViewController? webViewController;
  
  final isLoading = true.obs;
  final isDownloadingPDF = false.obs;
  final isDownloadingPPTX = false.obs;
  final isEditing = false.obs;
  final editingText = ''.obs;
  final editingElementId = ''.obs;
  
  // Storage for multi-page screenshots
  List<Uint8List> _capturedScreenshots = [];
  Map<String, dynamic> _screenshotDimensions = {};

  @override
  void onInit() {
    super.onInit();
    infographic = Get.arguments as InfographicModel;
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void onWebViewCreated(InAppWebViewController controller) {
    webViewController = controller;
    
    // Add JavaScript handler for text editing only
    controller.addJavaScriptHandler(
      handlerName: 'onTextClick',
      callback: (args) {
        if (args.isNotEmpty) {
          onTextElementClicked(Map<String, dynamic>.from(args[0]));
        }
      },
    );
  }

  void onLoadStop() async {
    // Add a delay to ensure WebView is fully rendered
    Future.delayed(const Duration(milliseconds: 1000), () {
      isLoading.value = false;
      _injectEditingScript();
    });
  }

  void _injectEditingScript() {
    const script = '''
      function makeElementsEditable() {
        const editableSelectors = [
          '.title', '.subtitle', '.heading', '.text', '.fact', '.statistic',
          'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', '.content', '.description'
        ];
        
        editableSelectors.forEach(selector => {
          const elements = document.querySelectorAll(selector);
          elements.forEach((element, index) => {
            if (!element.id) {
              element.id = selector.replace('.', '') + '_' + index;
            }
            element.style.cursor = 'pointer';
            element.addEventListener('click', function(e) {
              e.preventDefault();
              window.flutter_inappwebview.callHandler('onTextClick', {
                id: element.id,
                text: element.textContent || element.innerText
              });
            });
          });
        });
      }
      
      function updateElementText(id, newText) {
        const element = document.getElementById(id);
        if (element) {
          element.textContent = newText;
        }
      }
      
      makeElementsEditable();
    ''';
    
    webViewController?.evaluateJavascript(source: script);
  }

  void onTextElementClicked(Map<String, dynamic> data) {
    editingElementId.value = data['id'];
    editingText.value = data['text'];
    isEditing.value = true;
  }

  void updateTextElement() {
    if (editingElementId.value.isNotEmpty && editingText.value.isNotEmpty) {
      webViewController?.evaluateJavascript(
        source: "updateElementText('${editingElementId.value}', '${editingText.value.replaceAll("'", "\\'")}');",
      );
    }
    cancelEditing();
  }

  void cancelEditing() {
    isEditing.value = false;
    editingText.value = '';
    editingElementId.value = '';
  }

  Future<void> testPermissions() async {
    print('🔍 Testing permissions...');
    
    final storageStatus = await Permission.storage.status;
    print('🔍 Storage permission status: $storageStatus');
    
    try {
      final photosStatus = await Permission.photos.status;
      print('🔍 Photos permission status: $photosStatus');
    } catch (e) {
      print('🔍 Photos permission error: $e');
    }
    
    Get.snackbar(
      'Permission Status',
      'Storage: $storageStatus\nCheck console for details',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue[100],
      colorText: Colors.blue[800],
    );
  }

  Future<void> testScreenshotCapability() async {
    print('🧪 Testing full content capture capability...');
    
    try {
      if (webViewController == null) {
        throw Exception('WebView controller not initialized');
      }
      
      // Test full content capture
      final Uint8List? screenshotBytes = await _captureFullWebViewContent();
      
      if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
        print('✅ Full content captured successfully: ${screenshotBytes.length} bytes');
        Get.snackbar(
          'Full Content Test',
          'Full content captured: ${screenshotBytes.length} bytes',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        throw Exception('Full content capture returned null or empty');
      }
    } catch (e) {
      print('❌ Full content capture test failed: $e');
      Get.snackbar(
        'Capture Test Failed',
        'Error: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  // JavaScript getBoundingClientRect() approach for precise slide capture
  Future<Uint8List?> _captureFullWebViewContent() async {
    try {
      if (webViewController == null) {
        throw Exception('WebView controller not initialized');
      }
      
      // Clear previous screenshots to prevent accumulation
      _capturedScreenshots.clear();
      
      print('📸 Using JavaScript getBoundingClientRect() approach for precise slide capture');
      
      // Step 1: Inject JavaScript function to get slide rectangles
      await _injectSlideDetectionScript();
      
      // Step 2: Get all slide rectangles using JavaScript
      final slideRects = await _getSlidesRects();
      
      if (slideRects.isEmpty) {
        throw Exception('No slides detected in content');
      }
      
      print('📸 Detected ${slideRects.length} slides with precise boundaries');
      
      // Step 2.5: Deduplicate overlapping slides
      final deduplicatedRects = _deduplicateSlideRects(slideRects);
      print('📸 After deduplication: ${deduplicatedRects.length} unique slides');
      
      // Step 3: Get device pixel ratio for accurate cropping
      final devicePixelRatio = await webViewController!.evaluateJavascript(source: 'window.devicePixelRatio') as num;
      print('📸 Device pixel ratio: $devicePixelRatio');
      
      // Step 4: Capture and crop each slide
      final List<Uint8List> slideImages = [];
      
      for (int i = 0; i < deduplicatedRects.length; i++) {
        final rect = deduplicatedRects[i];
        print('📸 Processing slide ${i + 1}/${slideRects.length}');
        print('📸 Slide rect: top=${rect['top']}, left=${rect['left']}, width=${rect['width']}, height=${rect['height']}');
        
        // Scroll to slide position
        await webViewController!.evaluateJavascript(
          source: 'window.scrollTo(0, ${rect['top']});'
        );
        
  // Wait for paint completion (slightly increased to handle slow paints)
  await Future.delayed(const Duration(milliseconds: 700));
        
        // Take full viewport screenshot
        final fullScreenshot = await webViewController!.takeScreenshot();
        if (fullScreenshot == null) {
          print('❌ Failed to capture screenshot for slide ${i + 1}');
          continue;
        }
        
        print('📸 Full screenshot captured: ${fullScreenshot.length} bytes');
        
        // Crop the slide from the screenshot
        final croppedSlide = await _cropSlideFromScreenshot(
          fullScreenshot, 
          rect, 
          devicePixelRatio.toDouble(),
          i + 1
        );
        
        if (croppedSlide != null) {
          slideImages.add(croppedSlide);
          print('📸 Slide ${i + 1} cropped and saved: ${croppedSlide.length} bytes');
        }
      }
      
      if (slideImages.isEmpty) {
        throw Exception('No slides were successfully captured');
      }
      
      print('📸 Successfully captured ${slideImages.length} precise slides using getBoundingClientRect()');
      
      // Store slides for export
      _capturedScreenshots = slideImages;
      _screenshotDimensions = {
        'slideCount': slideImages.length,
        'method': 'getBoundingClientRect',
      };
      
      return slideImages.isNotEmpty ? slideImages[0] : null;
      
    } catch (e) {
      print('❌ Error in precise slide capture: $e');
      rethrow;
    }
  }

  // Inject JavaScript function to detect slide boundaries
  Future<void> _injectSlideDetectionScript() async {
    const script = '''
      window.getSlidesRects = function(selector) {
        // Try multiple selectors to find slide elements
        const selectors = [
          selector || '.slide',
          '.infographic-section',
          '.section',
          '.slide-content',
          '.page',
          '.card',
          '.panel',
          'section',
          '[class*="slide"]',
          '[class*="section"]'
        ];
        
        let elements = [];
        
        // Try each selector until we find elements
        for (const sel of selectors) {
          try {
            const found = document.querySelectorAll(sel);
            if (found.length > 0) {
              elements = Array.from(found);
              console.log('Found', elements.length, 'elements with selector:', sel);
              break;
            }
          } catch (e) {
            console.log('Selector failed:', sel, e);
          }
        }
        
        // If no specific slide elements found, analyze content for natural boundaries
        if (elements.length === 0) {
          console.log('No slide elements found, analyzing content for natural boundaries');
          
          // Find all significant content blocks
          const contentBlocks = document.querySelectorAll('div, section, article, main, .content, .block, .panel, .card');
          const blockPositions = [];
          
          contentBlocks.forEach(block => {
            const rect = block.getBoundingClientRect();
            const computedStyle = window.getComputedStyle(block);
            
            // Only consider blocks with significant height and visible content
            if (rect.height > 100 && computedStyle.display !== 'none' && computedStyle.visibility !== 'hidden') {
              blockPositions.push({
                top: rect.top + window.pageYOffset,
                bottom: rect.bottom + window.pageYOffset,
                height: rect.height,
                element: block
              });
            }
          });
          
          // Sort by position
          blockPositions.sort((a, b) => a.top - b.top);
          
          // Create slides based on content blocks with minimal padding
          const virtualSlides = [];
          const viewportHeight = window.innerHeight;
          const minSlideHeight = 200; // Minimum slide height
          const padding = 20; // Minimal padding around content
          
          if (blockPositions.length > 0) {
            let currentSlideStart = Math.max(0, blockPositions[0].top - padding);
            
            for (let i = 0; i < blockPositions.length; i++) {
              const block = blockPositions[i];
              const nextBlock = blockPositions[i + 1];
              
              // Determine slide end
              let slideEnd;
              if (nextBlock) {
                // Check if there's a significant gap to next block
                const gap = nextBlock.top - block.bottom;
                if (gap > 50) { // 50px gap indicates slide boundary
                  slideEnd = block.bottom + padding;
                } else {
                  continue; // Continue to next block
                }
              } else {
                // Last block
                slideEnd = block.bottom + padding;
              }
              
              const slideHeight = slideEnd - currentSlideStart;
              
              // Only create slide if it has reasonable height
              if (slideHeight >= minSlideHeight) {
                virtualSlides.push({
                  top: currentSlideStart,
                  left: 0,
                  width: window.innerWidth,
                  height: slideHeight,
                  bottom: slideEnd,
                  right: window.innerWidth
                });
                
                // Start next slide after current one
                if (nextBlock) {
                  currentSlideStart = Math.max(slideEnd, nextBlock.top - padding);
                }
              }
            }
          }
          
          // Fallback: create viewport-based slides if content analysis failed
          if (virtualSlides.length === 0) {
            console.log('Content analysis failed, using viewport-based slides');
            const contentHeight = Math.max(
              document.body.scrollHeight,
              document.documentElement.scrollHeight
            );
            
            for (let y = 0; y < contentHeight; y += viewportHeight) {
              const height = Math.min(viewportHeight, contentHeight - y);
              virtualSlides.push({
                top: y,
                left: 0,
                width: window.innerWidth,
                height: height,
                bottom: y + height,
                right: window.innerWidth
              });
            }
          }
          
          console.log('Created', virtualSlides.length, 'virtual slides with tight boundaries');
          return virtualSlides;
        }
        
        // Get bounding rectangles for found elements
        const rects = elements.map((el, index) => {
          const rect = el.getBoundingClientRect();
          const absoluteRect = {
            top: rect.top + window.pageYOffset,
            left: rect.left + window.pageXOffset,
            width: rect.width,
            height: rect.height,
            bottom: rect.bottom + window.pageYOffset,
            right: rect.right + window.pageXOffset
          };
          
          console.log('Slide', index + 1, 'rect:', absoluteRect);
          return absoluteRect;
        });
        
        // Sort by top position
        rects.sort((a, b) => a.top - b.top);
        
        return rects;
      };
      
      console.log('Slide detection script injected successfully');
    ''';
    
    await webViewController!.evaluateJavascript(source: script);
    print('📸 Slide detection script injected');
  }

  // Get slide rectangles using JavaScript
  Future<List<Map<String, dynamic>>> _getSlidesRects() async {
    try {
      final result = await webViewController!.evaluateJavascript(source: 'window.getSlidesRects()');
      
      if (result is List) {
        final slideRects = <Map<String, dynamic>>[];
        
        for (var rect in result) {
          if (rect is Map) {
            slideRects.add({
              'top': (rect['top'] as num).toDouble(),
              'left': (rect['left'] as num).toDouble(),
              'width': (rect['width'] as num).toDouble(),
              'height': (rect['height'] as num).toDouble(),
              'bottom': (rect['bottom'] as num).toDouble(),
              'right': (rect['right'] as num).toDouble(),
            });
          }
        }
        
        return slideRects;
      }
      
      throw Exception('Invalid slide rects format returned from JavaScript');
      
    } catch (e) {
      print('❌ Error getting slide rects: $e');
      rethrow;
    }
  }

  // Deduplicate overlapping or duplicate slide rectangles
  List<Map<String, dynamic>> _deduplicateSlideRects(List<Map<String, dynamic>> rects) {
    if (rects.isEmpty) return rects;
    
    // Sort by top position
    final sortedRects = List<Map<String, dynamic>>.from(rects);
    sortedRects.sort((a, b) => (a['top'] as double).compareTo(b['top'] as double));
    
    final deduplicated = <Map<String, dynamic>>[];
    final overlapThreshold = 0.3; // 30% overlap threshold
    
    for (int i = 0; i < sortedRects.length; i++) {
      final current = sortedRects[i];
      bool isDuplicate = false;
      
      // Check if this rect overlaps significantly with any already added rect
      for (final existing in deduplicated) {
        final overlap = _calculateOverlap(current, existing);
        if (overlap > overlapThreshold) {
          isDuplicate = true;
          print('📸 Skipping duplicate slide: ${i + 1} (overlap: ${(overlap * 100).toStringAsFixed(1)}%)');
          break;
        }
      }
      
      if (!isDuplicate) {
        deduplicated.add(current);
      }
    }
    
    return deduplicated;
  }

  // Calculate overlap ratio between two rectangles (0.0 to 1.0)
  double _calculateOverlap(Map<String, dynamic> rect1, Map<String, dynamic> rect2) {
    final top1 = rect1['top'] as double;
    final bottom1 = rect1['bottom'] as double;
    final top2 = rect2['top'] as double;
    final bottom2 = rect2['bottom'] as double;
    
    // Calculate vertical overlap
    final overlapTop = top1 > top2 ? top1 : top2;
    final overlapBottom = bottom1 < bottom2 ? bottom1 : bottom2;
    
    if (overlapTop >= overlapBottom) {
      return 0.0; // No overlap
    }
    
    final overlapHeight = overlapBottom - overlapTop;
    final rect1Height = bottom1 - top1;
    final rect2Height = bottom2 - top2;
    final minHeight = rect1Height < rect2Height ? rect1Height : rect2Height;
    
    if (minHeight == 0) return 0.0;
    
    // Return overlap as ratio of the smaller rectangle
    return overlapHeight / minHeight;
  }

  // Crop slide from full screenshot using precise coordinates with smart boundary detection
  Future<Uint8List?> _cropSlideFromScreenshot(
    Uint8List screenshotBytes, 
    Map<String, dynamic> rect, 
    double devicePixelRatio,
    int slideNumber
  ) async {
    try {
      // Decode the screenshot image
      final image = img.decodeImage(screenshotBytes);
      if (image == null) {
        print('❌ Failed to decode screenshot for slide $slideNumber');
        return null;
      }
      
      print('📸 Original screenshot size: ${image.width}x${image.height}');
      
      // Get viewport dimensions for reference
      final viewportWidth = (image.width / devicePixelRatio).round();
      final viewportHeight = (image.height / devicePixelRatio).round();
      
      // Calculate crop coordinates with device pixel ratio
  var cropX = ((rect['left'] as double) * devicePixelRatio).round();

  // Compute cropY relative to the actual scrolled position. This handles
  // cases where a fixed header or other offset causes the element's
  // top to not align exactly with the viewport top after scroll.
  final actualScroll = await webViewController!.evaluateJavascript(source: 'window.pageYOffset') as num;
  var cropY = (((rect['top'] as double) - actualScroll) * devicePixelRatio).round();
  if (cropY < 0) cropY = 0;
      var cropWidth = ((rect['width'] as double) * devicePixelRatio).round();
      var cropHeight = ((rect['height'] as double) * devicePixelRatio).round();
      
      // Smart boundary adjustment to remove excessive white space
      
      // 1. Ensure we don't crop beyond image bounds
      cropX = cropX.clamp(0, image.width - 1);
      cropWidth = cropWidth.clamp(1, image.width - cropX);
      
      // 2. For height, be more intelligent about cropping
      // If the slide height is very large compared to viewport, limit it
      final maxReasonableHeight = (viewportHeight * devicePixelRatio * 1.2).round(); // 120% of viewport
      if (cropHeight > maxReasonableHeight) {
        cropHeight = maxReasonableHeight;
        print('📸 Limited slide $slideNumber height to reasonable size: $cropHeight pixels');
      }
      
      // 3. Ensure crop height doesn't exceed image height
      cropHeight = cropHeight.clamp(1, image.height - cropY);
      
      // 4. Smart content detection to trim white space
      final contentBounds = _detectContentBounds(image, cropX, cropY, cropWidth, cropHeight);
      if (contentBounds != null) {
        cropX = contentBounds['x']!;
        cropY = contentBounds['y']!;
        cropWidth = contentBounds['width']!;
        cropHeight = contentBounds['height']!;
        print('📸 Adjusted slide $slideNumber bounds to remove white space: x=$cropX, y=$cropY, w=$cropWidth, h=$cropHeight');
      }
      
      print('📸 Final crop coordinates for slide $slideNumber: x=$cropX, y=$cropY, w=$cropWidth, h=$cropHeight');
      
      // Final validation
      if (cropWidth <= 0 || cropHeight <= 0) {
        print('❌ Invalid final crop dimensions for slide $slideNumber');
        return null;
      }
      
      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );
      
      print('📸 Final cropped slide $slideNumber size: ${croppedImage.width}x${croppedImage.height}');
      
      // Encode as PNG
      final pngBytes = img.encodePng(croppedImage);
      return Uint8List.fromList(pngBytes);
      
    } catch (e) {
      print('❌ Error cropping slide $slideNumber: $e');
      return null;
    }
  }

  // Detect actual content bounds to trim excessive white space
  Map<String, int>? _detectContentBounds(img.Image image, int startX, int startY, int width, int height) {
    try {
      // Sample points to detect content vs white space
      final samplePoints = <Map<String, int>>[];
      final step = 20; // Sample every 20 pixels
      
      // Sample top, bottom, left, right edges
      for (int x = startX; x < startX + width; x += step) {
        for (int y = startY; y < startY + height; y += step) {
          if (x < image.width && y < image.height) {
            final pixel = image.getPixel(x, y);
            final r = pixel.r;
            final g = pixel.g;
            final b = pixel.b;
            
            // Consider non-white pixels as content (with some tolerance)
            if (r < 240 || g < 240 || b < 240) {
              samplePoints.add({'x': x, 'y': y});
            }
          }
        }
      }
      
      if (samplePoints.isEmpty) {
        return null; // No content detected, use original bounds
      }
      
      // Find content boundaries
      final minX = samplePoints.map((p) => p['x']!).reduce((a, b) => a < b ? a : b);
      final maxX = samplePoints.map((p) => p['x']!).reduce((a, b) => a > b ? a : b);
      final minY = samplePoints.map((p) => p['y']!).reduce((a, b) => a < b ? a : b);
      final maxY = samplePoints.map((p) => p['y']!).reduce((a, b) => a > b ? a : b);
      
      // Add small padding around content
      final padding = 10;
      final contentX = (minX - padding).clamp(startX, image.width - 1);
      final contentY = (minY - padding).clamp(startY, image.height - 1);
      final contentWidth = (maxX - contentX + padding * 2).clamp(1, image.width - contentX);
      final contentHeight = (maxY - contentY + padding * 2).clamp(1, image.height - contentY);
      
      // Only use detected bounds if they're significantly different and smaller
      if (contentWidth < width * 0.9 || contentHeight < height * 0.9) {
        return {
          'x': contentX,
          'y': contentY,
          'width': contentWidth,
          'height': contentHeight,
        };
      }
      
      return null; // Use original bounds
      
    } catch (e) {
      print('❌ Error detecting content bounds: $e');
      return null;
    }
  }



  Future<void> _createPDFFromScreenshot(Uint8List imageBytes) async {
    try {
      print('📄 Creating multi-page PDF from ${_capturedScreenshots.length} screenshots...');
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Use captured screenshots if available, otherwise single screenshot
      final screenshots = _capturedScreenshots.isNotEmpty ? _capturedScreenshots : [imageBytes];
      
      // Add each screenshot as a separate page
      for (int i = 0; i < screenshots.length; i++) {
        print('📄 Adding page ${i + 1}/${screenshots.length}');
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Clean header with slide info
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.only(bottom: 15),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Infographic Slide ${i + 1}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.Text(
                          '${i + 1} of ${screenshots.length}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 15),
                  
                  // Screenshot image with clean presentation
                  pw.Expanded(
                    child: pw.Container(
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey200,
                          width: 1,
                        ),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(screenshots[i]),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  pw.SizedBox(height: 10),
                  
                  // Footer with clean separation
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.only(top: 10),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: pw.Text(
                      'Generated with clean slide separation • Professional presentation format',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
      
      // Generate PDF bytes
      final pdfBytes = await pdf.save();
      print('📄 Multi-page PDF generated: ${pdfBytes.length} bytes with ${screenshots.length} pages');
      
      // Save PDF file
      final filePath = await _savePDFFile(pdfBytes);
      
      isDownloadingPDF.value = false;
      
      Get.snackbar(
        'Success',
        'PDF with ${screenshots.length} pages saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
      
      // Share the file
      await Share.shareXFiles([XFile(filePath)]);
      
    } catch (e) {
      print('❌ Error creating PDF: $e');
      rethrow;
    }
  }

  Future<void> _createPPTXFromScreenshot(Uint8List imageBytes) async {
    try {
      print('🎞 Creating multi-slide PPTX from ${_capturedScreenshots.length} screenshots...');
      
      // Use captured screenshots if available, otherwise single screenshot
      final screenshots = _capturedScreenshots.isNotEmpty ? _capturedScreenshots : [imageBytes];
      
      // Create PPTX file structure with multiple slides
      final pptxBytes = await _generateMultiSlidePPTXFile(screenshots);
      
      // Save PPTX file
      final filePath = await _savePPTXFile(pptxBytes);
      
      print('🎞 Multi-slide PPTX generated: ${pptxBytes.length} bytes with ${screenshots.length} slides');
      
      isDownloadingPPTX.value = false;
      
      Get.snackbar(
        'Success',
        'PPTX with ${screenshots.length} slides created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
      
      // Share the file
      await Share.shareXFiles([XFile(filePath)]);
      
    } catch (e) {
      print('❌ Error creating PPTX: $e');
      rethrow;
    }
  }

  Future<Uint8List> _generateMultiSlidePPTXFile(List<Uint8List> screenshots) async {
    try {
      // Create ZIP archive for PPTX
      final archive = Archive();
      
      // Add [Content_Types].xml
      final contentTypesBuilder = StringBuffer();
      contentTypesBuilder.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-presentationml.presentation.main+xml"/>''');
      
      // Add content types for each slide
      for (int i = 1; i <= screenshots.length; i++) {
        contentTypesBuilder.write('''
  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-presentationml.slide+xml"/>''');
      }
      
      contentTypesBuilder.write('''
  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-presentationml.slideLayout+xml"/>
  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-presentationml.slideMaster+xml"/>
  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
</Types>''');
      
      final contentTypesComplete = contentTypesBuilder.toString();
      
      archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesComplete.length, utf8.encode(contentTypesComplete)));
      
      // Add _rels/.rels
      final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
      
      archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));
      
      // Generate relationships for multiple slides
      final presentationRelsBuilder = StringBuffer();
      presentationRelsBuilder.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>''');
      
      // Add relationship for each slide
      for (int i = 0; i < screenshots.length; i++) {
        presentationRelsBuilder.write('''
  <Relationship Id="rId${i + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide${i + 1}.xml"/>''');
      }
      
      presentationRelsBuilder.write('''
  <Relationship Id="rId${screenshots.length + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
</Relationships>''');
      
      final presentationRelsXml = presentationRelsBuilder.toString();
      archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', presentationRelsXml.length, utf8.encode(presentationRelsXml)));
      
      // Generate presentation.xml with multiple slides
      final presentationBuilder = StringBuffer();
      presentationBuilder.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:sldMasterIdLst>
    <p:sldMasterId id="2147483648" r:id="rId1"/>
  </p:sldMasterIdLst>
  <p:sldIdLst>''');
      
      // Add slide ID for each screenshot
      for (int i = 0; i < screenshots.length; i++) {
        presentationBuilder.write('''
    <p:sldId id="${256 + i}" r:id="rId${i + 2}"/>''');
      }
      
      presentationBuilder.write('''
  </p:sldIdLst>
  <p:sldSz cx="9144000" cy="6858000"/>
</p:presentation>''');
      
      final presentationXml = presentationBuilder.toString();
      archive.addFile(ArchiveFile('ppt/presentation.xml', presentationXml.length, utf8.encode(presentationXml)));
      
      // Generate slides and relationships for each screenshot
      for (int i = 0; i < screenshots.length; i++) {
        final slideNum = i + 1;
        
        // Add slide relationships
        final slideRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image$slideNum.png"/>
</Relationships>''';
        
        archive.addFile(ArchiveFile('ppt/slides/_rels/slide$slideNum.xml.rels', slideRelsXml.length, utf8.encode(slideRelsXml)));
        
        // Add slide XML with title and clean image layout
        final slideXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
      
      <!-- Slide Title -->
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="2" name="Title"/>
          <p:cNvSpPr>
            <a:spLocks noGrp="1"/>
          </p:cNvSpPr>
          <p:nvPr>
            <p:ph type="title"/>
          </p:nvPr>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm>
            <a:off x="457200" y="274638"/>
            <a:ext cx="8229600" cy="1143000"/>
          </a:xfrm>
        </p:spPr>
        <p:txBody>
          <a:bodyPr/>
          <a:lstStyle/>
          <a:p>
            <a:r>
              <a:rPr lang="en-US" sz="4400" b="1">
                <a:solidFill>
                  <a:schemeClr val="tx1"/>
                </a:solidFill>
              </a:rPr>
              <a:t>Infographic Slide $slideNum</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
      
      <!-- Main Content Image -->
      <p:pic>
        <p:nvPicPr>
          <p:cNvPr id="3" name="Content Section $slideNum"/>
          <p:cNvPicPr/>
          <p:nvPr/>
        </p:nvPicPr>
        <p:blipFill>
          <a:blip r:embed="rId2"/>
          <a:stretch>
            <a:fillRect/>
          </a:stretch>
        </p:blipFill>
        <p:spPr>
          <a:xfrm>
            <a:off x="457200" y="1600000"/>
            <a:ext cx="8229600" cy="4800000"/>
          </a:xfrm>
          <a:prstGeom prst="rect">
            <a:avLst/>
          </a:prstGeom>
          <a:effectLst>
            <a:outerShdw blurRad="50800" dist="38100" dir="2700000" algn="tl" rotWithShape="0">
              <a:srgbClr val="000000">
                <a:alpha val="40000"/>
              </a:srgbClr>
            </a:outerShdw>
          </a:effectLst>
        </p:spPr>
      </p:pic>
      
      <!-- Slide Number -->
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="4" name="Slide Number"/>
          <p:cNvSpPr/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm>
            <a:off x="8000000" y="6200000"/>
            <a:ext cx="1000000" cy="400000"/>
          </a:xfrm>
        </p:spPr>
        <p:txBody>
          <a:bodyPr/>
          <a:lstStyle/>
          <a:p>
            <a:r>
              <a:rPr lang="en-US" sz="1800">
                <a:solidFill>
                  <a:schemeClr val="tx1">
                    <a:alpha val="60000"/>
                  </a:schemeClr>
                </a:solidFill>
              </a:rPr>
              <a:t>$slideNum of ${screenshots.length}</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
      
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr>
    <a:masterClrMapping/>
  </p:clrMapOvr>
</p:sld>''';
        
        archive.addFile(ArchiveFile('ppt/slides/slide$slideNum.xml', slideXml.length, utf8.encode(slideXml)));
      }
      
      // Add minimal slideLayout, slideMaster, and theme files
      final slideLayoutXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <p:cSld name="Blank">
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr/>
    </p:spTree>
  </p:cSld>
</p:sldLayout>''';
      
      archive.addFile(ArchiveFile('ppt/slideLayouts/slideLayout1.xml', slideLayoutXml.length, utf8.encode(slideLayoutXml)));
      
      final slideMasterXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr/>
    </p:spTree>
  </p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
  <p:sldLayoutIdLst>
    <p:sldLayoutId id="2147483649"/>
  </p:sldLayoutIdLst>
</p:sldMaster>''';
      
      archive.addFile(ArchiveFile('ppt/slideMasters/slideMaster1.xml', slideMasterXml.length, utf8.encode(slideMasterXml)));
      
      final themeXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
  <a:themeElements>
    <a:clrScheme name="Office">
      <a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>
      <a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="1F497D"/></a:dk2>
      <a:lt2><a:srgbClr val="EEECE1"/></a:lt2>
      <a:accent1><a:srgbClr val="4F81BD"/></a:accent1>
      <a:accent2><a:srgbClr val="F79646"/></a:accent2>
      <a:accent3><a:srgbClr val="9BBB59"/></a:accent3>
      <a:accent4><a:srgbClr val="8064A2"/></a:accent4>
      <a:accent5><a:srgbClr val="4BACC6"/></a:accent5>
      <a:accent6><a:srgbClr val="F366CC"/></a:accent6>
      <a:hlink><a:srgbClr val="0000FF"/></a:hlink>
      <a:folHlink><a:srgbClr val="800080"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Office">
      <a:majorFont>
        <a:latin typeface="Calibri"/>
      </a:majorFont>
      <a:minorFont>
        <a:latin typeface="Calibri"/>
      </a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Office">
      <a:fillStyleLst>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
      </a:fillStyleLst>
      <a:lnStyleLst>
        <a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>
      </a:lnStyleLst>
      <a:effectStyleLst>
        <a:effectStyle><a:effectLst/></a:effectStyle>
      </a:effectStyleLst>
      <a:bgFillStyleLst>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
      </a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
</a:theme>''';
      
      archive.addFile(ArchiveFile('ppt/theme/theme1.xml', themeXml.length, utf8.encode(themeXml)));
      
      // Add all screenshot image files
      for (int i = 0; i < screenshots.length; i++) {
        final imageNum = i + 1;
        archive.addFile(ArchiveFile('ppt/media/image$imageNum.png', screenshots[i].length, screenshots[i]));
      }
      
      // Create ZIP file
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      
      return Uint8List.fromList(zipBytes!);
      
    } catch (e) {
      print('❌ Error generating PPTX file: $e');
      rethrow;
    }
  }

  Future<String> _savePDFFile(Uint8List pdfBytes) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'infographic_$timestamp.pdf';
    final filePath = '${appDocDir.path}/$filename';
    
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    
    print('📄 PDF saved to: $filePath');
    return filePath;
  }

  Future<String> _savePPTXFile(Uint8List pptxBytes) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'infographic_$timestamp.pptx';
    final filePath = '${appDocDir.path}/$filename';
    
    final file = File(filePath);
    await file.writeAsBytes(pptxBytes);
    
    print('🎞 PPTX saved to: $filePath');
    return filePath;
  }

  // Screenshot-based export methods called by UI
  Future<void> downloadAsPDF() async {
    try {
      isDownloadingPDF.value = true;
      
      // No permission needed - we're saving to app's private directory
      // getApplicationDocumentsDirectory() doesn't require storage permission
      
      Get.snackbar(
        "Generating PDF",
        "Capturing full content and creating PDF...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
      );
      
      // Capture full WebView content
      final screenshotBytes = await _captureFullWebViewContent();
      if (screenshotBytes == null) {
        throw Exception('Failed to capture full WebView content');
      }
      
      // Create PDF from screenshot
      await _createPDFFromScreenshot(screenshotBytes);
      
    } catch (e) {
      print('❌ Error in PDF export: $e');
      isDownloadingPDF.value = false;
      Get.snackbar(
        'Error',
        'Failed to export PDF: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  Future<void> downloadAsPPTX() async {
    try {
      isDownloadingPPTX.value = true;
      
      // No permission needed - we're saving to app's private directory
      // getApplicationDocumentsDirectory() doesn't require storage permission
      
      Get.snackbar(
        "Generating PPTX",
        "Capturing full content and creating presentation...",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
      );
      
      // Capture full WebView content
      final screenshotBytes = await _captureFullWebViewContent();
      if (screenshotBytes == null) {
        throw Exception('Failed to capture full WebView content');
      }
      
      // Create PPTX from screenshot
      await _createPPTXFromScreenshot(screenshotBytes);
      
    } catch (e) {
      print('❌ Error in PPTX export: $e');
      isDownloadingPPTX.value = false;
      Get.snackbar(
        'Error',
        'Failed to export PPTX: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      PermissionStatus permissionStatus = await Permission.storage.request();
      
      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        permissionStatus = await Permission.photos.request();
      }
      
      if (!permissionStatus.isGranted) {
        final shouldContinue = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to save files. Please grant permission to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        );
        
        if (shouldContinue == true) {
          permissionStatus = await Permission.storage.request();
          if (!permissionStatus.isGranted) {
            permissionStatus = await Permission.photos.request();
          }
          
          if (!permissionStatus.isGranted) {
            final openSettings = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Permission Required'),
                content: const Text(
                  'Storage permission is required to save files. Please enable it in app settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
            
            if (openSettings == true) {
              await openAppSettings();
            }
            return false;
          }
        } else {
          return false;
        }
      }
      
      return permissionStatus.isGranted;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  void regenerateInfographic() {
    Get.back();
  }
}