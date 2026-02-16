import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../data/services/gemini_service.dart';
import '../../../routes/app_pages.dart';
import 'dart:developer' as dp;

class HomeController extends GetxController {
  final TextEditingController promptController = TextEditingController();
  final GeminiService _geminiService = GeminiService();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  // Loading tips and state for friendly loading UI
  final List<String> loadingTips = [
    'Tip: Try short descriptive prompts for clearer slides.',
    'Tip: Use keywords like "timeline", "statistics", "compare".',
    'Tip: Add a target audience to the prompt for tailored visuals.',
    'Tip: Combine colors like blue and white for professional slides.'
  ];
  final currentLoadingTip = ''.obs;
  Timer? _tipsTimer;

  @override
  void onInit() {
    super.onInit();
    // initialize current tip
    currentLoadingTip.value = loadingTips.first;

    // react to loading state to start/stop the tip timer
    ever(isLoading, (bool loading) {
      if (loading) {
        // start cycling tips every 2 seconds
        _tipsTimer?.cancel();
        _tipsTimer = Timer.periodic(const Duration(seconds: 2), (t) {
          final nextIndex = (loadingTips.indexOf(currentLoadingTip.value) + 1) % loadingTips.length;
          currentLoadingTip.value = loadingTips[nextIndex];
        });
      } else {
        _tipsTimer?.cancel();
        currentLoadingTip.value = loadingTips.first;
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    promptController.dispose();
    _tipsTimer?.cancel();
    super.onClose();
  }

  Future<void> generateInfographic() async {
    // if (promptController.text.trim().isEmpty) {
    //   errorMessage.value = 'Please enter a prompt';
    //   return;
    // }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final infographic = await _geminiService.generateInfographic(
        promptController.text.trim(),
        // 'variables in cpp',
      );
      //       final infographic = InfographicModel(
      //         htmlCode: '''
      //   <div class=\"infographic\">\n    <header>\n      <h1 class=\"title\">Variables in C++</h1>\n      <p class=\"subtitle\">Understanding the Building Blocks of Your Code</p>\n    </header>\n\n    <section class=\"overview\">\n      <div class=\"overview-item\">\n        <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' width='48' height='48'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-12h2v4h-2v-4zm0 6h2v2h-2v-2z'/%3E%3C/svg%3E\" alt=\"Definition Icon\" class=\"icon\">\n        <p class=\"fact\">Variables store data.</p>\n        <p class=\"description\">Variables are named storage locations used to hold values that can change during program execution. They're fundamental to any C++ program.</p>\n      </div>\n\n      <div class=\"overview-item\">\n        <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' width='48' height='48'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-5 13.5l-2-2 2-2 2 2-2 2zm10 0l-2-2 2-2 2 2-2 2z'/%3E%3C/svg%3E\" alt=\"Declaration Icon\" class=\"icon\">\n        <p class=\"fact\">Declaration & Initialization are key.</p>\n        <p class=\"description\">Declare a variable by specifying its data type and name. Initialize it with a value.</p>\n      </div>\n    </section>\n\n    <section class=\"types\">\n      <h2 class=\"section-title\">Common Data Types</h2>\n      <div class=\"types-grid\">\n        <div class=\"type-item\">\n          <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' width='32' height='32'%3E%3Cpath d='M2 22h20V2H2v20zm2-2v-2h2v2H4zm4 0v-2h2v2H8zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2zM4 16v-2h2v2H4zm4 0v-2h2v2H8zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2zM4 10v-2h2v2H4zm4 0v-2h2v2H8zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2zM4 4v-2h2v2H4zm4 0v-2h2v2H8zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2zm4 0v-2h2v2h-2z'/%3E%3C/svg%3E\" alt=\"Integer Icon\" class=\"icon-small\">\n          <p class=\"type-name\">int</p>\n          <p class=\"type-description\">Stores whole numbers (e.g., 10, -5, 0)</p>\n        </div>\n        <div class=\"type-item\">\n          <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' width='32' height='32'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-4 13h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2z'/%3E%3C/svg%3E\" alt=\"Float Icon\" class=\"icon-small\">\n          <p class=\"type-name\">float</p>\n          <p class=\"type-description\">Stores single-precision floating-point numbers (e.g., 3.14, -2.5)</p>\n        </div>\n        <div class=\"type-item\">\n          <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' width='32' height='32'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-5 12h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2z'/%3E%3C/svg%3E\" alt=\"Double Icon\" class=\"icon-small\">\n          <p class=\"type-name\">double</p>\n          <p class=\"type-description\">Stores double-precision floating-point numbers (e.g., 3.14159, -2.5)</p>\n        </div>\n        <div class=\"type-item\">\n          <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' width='32' height='32'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-4 13h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2z'/%3E%3C/svg%3E\" alt=\"Char Icon\" class=\"icon-small\">\n          <p class=\"type-name\">char</p>\n          <p class=\"type-description\">Stores a single character (e.g., 'A', 'z')</p>\n        </div>\n        <div class=\"type-item\">\n          <img src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='currentColor' width='32' height='32'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-5 13h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2zm-8-4h2v-2h-2v2zm4 0h2v-2h-2v2zm4 0h2v-2h-2v2z'/%3E%3C/svg%3E\" alt=\"Bool Icon\" class=\"icon-small\">\n          <p class=\"type-name\">bool</p>\n          <p class=\"type-description\">Stores a boolean value (true or false)</p>\n        </div>\n      </div>\n    </section>\n\n    <section class=\"scope\">\n      <h2 class=\"section-title\">Variable Scope</h2>\n      <div class=\"scope-item\">\n        <p class=\"fact\">Local Variables:</p>\n        <p class=\"description\">Defined inside a function or block. Only accessible within that scope.</p>\n      </div>\n      <div class=\"scope-item\">\n        <p class=\"fact\">Global Variables:</p>\n        <p class=\"description\">Defined outside any function. Accessible from anywhere in the code.</p>\n      </div>\n    </section>\n\n    <section class=\"tips\">\n      <h2 class=\"section-title\">Best Practices</h2>\n      <ul class=\"tips-list\">\n        <li><span class=\"tip-item\">Use meaningful variable names.</span></li>\n        <li><span class=\"tip-item\">Initialize variables when you declare them.</span></li>\n        <li><span class=\"tip-item\">Choose the appropriate data type.</span></li>\n        <li><span class=\"tip-item\">Avoid global variables when possible.</span></li>\n        <li><span class=\"tip-item\">Comment your code for clarity.</span></li>\n      </ul>\n    </section>\n\n    <footer class=\"footer\">\n      <p class=\"copyright\">© 2024 Infographic by AI</p>\n    </footer>\n  </div>\n
      // ''',
      //         cssCode: '''
      // <style>\n    body {\n      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;\n      margin: 0;\n      padding: 0;\n      background-color: #f4f4f4;\n      color: #333;\n      display: flex;\n      justify-content: center;\n      align-items: center;\n      min-height: 100vh;\n      background: linear-gradient(135deg, #f0f8ff, #e0ffff);\n    }\n\n    .infographic {\n      width: 90%; /* Adjusted for mobile */\n      max-width: 400px; /* Further adjustment for better readability */\n      background-color: #fff;\n      border-radius: 12px;\n      box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);\n      overflow: hidden;\n      transition: transform 0.3s ease-in-out;\n      margin: 20px 0;\n      padding-bottom: 20px;\n    }\n\n    .infographic:hover {\n      transform: scale(1.02);\n    }\n\n    header {\n      background-color: #3498db;\n      color: #fff;\n      padding: 20px;\n      text-align: center;\n      border-bottom: 1px solid #2980b9;\n    }\n\n    .title {\n      font-size: 1.8em;\n      margin-bottom: 5px;\n    }\n\n    .subtitle {\n      font-size: 1em;\n      opacity: 0.8;\n    }\n\n    .overview, .types, .scope {\n      padding: 15px 20px;\n    }\n\n    .overview {\n      display: flex;\n      flex-direction: column;\n      gap: 20px;\n    }\n\n    .overview-item {\n      background-color: #ecf0f1;\n      padding: 15px;\n      border-radius: 8px;\n      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);\n      display: flex;\n      align-items: center;\n      gap: 15px;\n    }\n\n    .icon {\n      width: 48px;\n      height: 48px;\n      color: #3498db;\n    }\n\n    .fact {\n      font-size: 1.1em;\n      font-weight: 600;\n      margin-bottom: 5px;\n    }\n\n    .description {\n      font-size: 0.95em;\n      color: #555;\n    }\n\n    .section-title {\n      font-size: 1.5em;\n      font-weight: 600;\n      margin-bottom: 15px;\n      color: #2c3e50;\n      border-bottom: 2px solid #ddd;\n      padding-bottom: 8px;\n    }\n\n    .types-grid {\n      display: grid;\n      grid-template-columns: repeat(2, 1fr);\n      gap: 15px;\n    }\n\n    .type-item {\n      background-color: #f9f9f9;\n      padding: 12px;\n      border-radius: 8px;\n      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);\n      text-align: center;\n    }\n\n    .icon-small {\n      width: 32px;\n      height: 32px;\n      margin-bottom: 8px;\n      color: #3498db;\n    }\n\n    .type-name {\n      font-size: 1.1em;\n      font-weight: 600;\n      margin-bottom: 5px;\n    }\n\n    .type-description {\n      font-size: 0.9em;\n      color: #555;\n    }\n\n    .scope {\n      display: flex;\n      flex-direction: column;\n      gap: 15px;\n    }\n\n    .scope-item {\n      background-color: #ecf0f1;\n      padding: 15px;\n      border-radius: 8px;\n      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);\n    }\n\n    .tips {\n      padding: 15px 20px;\n    }\n\n    .tips-list {\n      list-style: none;\n      padding: 0;\n    }\n\n    .tip-item {\n      font-size: 1em;\n      padding: 8px 0;\n      border-bottom: 1px solid #eee;\n    }\n\n    .tip-item:last-child {\n      border-bottom: none;\n    }\n\n    .footer {\n      text-align: center;\n      font-size: 0.8em;\n      color: #777;\n      padding: 15px 0;\n      border-top: 1px solid #eee;\n    }\n\n    @media (max-width: 600px) {\n      .infographic {\n        width: 95%;\n      }\n\n      .types-grid {\n        grid-template-columns: 1fr;\n      }\n      .overview-item {\n        flex-direction: column;\n        align-items: flex-start;\n      }\n\n      .icon {\n          width: 32px;\n          height: 32px;\n      }\n    }\n  </style>\n
      // ''',
      //   prompt: promptController.text.trim(),
      // );
      if (infographic != null) {
        dp.log('Htmlcode${infographic.htmlCode}');
        dp.log('Csscode${infographic.cssCode}');
        // Navigate to infographic viewer with the generated data
        Get.toNamed(Routes.INFOGRAPHIC_VIEWER, arguments: infographic);
      } else {
        dp.log('Failed to generate infographic');
      }
    } catch (e) {
      dp.log(e.toString());
      errorMessage.value = 'An error occurred: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
