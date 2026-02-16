import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  
  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background with wave-like shape
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePainter(),
              child: Container(),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                  const SizedBox(height: 28),

                  // Centered title and subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Smart Slides',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'AI-powered slide decks in seconds',
                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Small feature highlights (centered, white bg to match app)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _FeatureChip(icon: Icons.auto_awesome, label: 'Designs'),
                      SizedBox(width: 8),
                      _FeatureChip(icon: Icons.bar_chart, label: 'Charts'),
                      SizedBox(width: 8),
                      _FeatureChip(icon: Icons.palette, label: 'Themes'),
                    ],
                  ),

                  const SizedBox(height: 18),
                  
                  // Prompt Input Field (improved)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(() => TextField(
                    controller: controller.promptController,
                    enabled: !controller.isLoading.value,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Write a prompt — e.g. "AI trends 2025: 6-slide presentation"',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => controller.clearError(),
                    onSubmitted: (value) => controller.generateInfographic(),
                  )),
                  const SizedBox(height: 12),
                  Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.generateInfographic,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Generate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ))
                ],
              ),
            ),
                  
                  const SizedBox(height: 40),
                  
                  // Example Topics
                  const Text(
                    'Example Topics:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tags Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildTag('5G Technology'),
                      _buildTag('Dog Breeds'),
                      _buildTag('Public Issues'),
                      _buildTag('Learning Plans'),
                      _buildTag('Office Culture'),
                      _buildTag('Fan Pages'),
                      _buildTag('Freelance Work'),
                      _buildTag('Objectives'),
                      _buildTag('Furniture'),
                      _buildTag('Climate Change'),
                      _buildTag('AI Trends'),
                    ],
                  ),
                  
                  // Footer - Hide when keyboard is visible
                  if (!isKeyboardVisible) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    const Column(
                      children: [
                        Text(
                          'Innovation starts where imagination ends.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'AI that sees beyond limits ✨',
                          style: TextStyle(
                        fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ] else
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          

          // Error Message (if any)
          Obx(() => controller.errorMessage.value.isNotEmpty
              ? Positioned(
                  top: 100,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink()),

          // Friendly Loading Overlay
          Obx(() {
            if (!controller.isLoading.value) return const SizedBox.shrink();
            return Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated logo / spinner
                      _LoadingLogo(),
                      const SizedBox(height: 18),
                      // Animated dot progress
                      _AnimatedDots(),
                      const SizedBox(height: 14),
                      // Cycling tip text
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 36),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(() => Text(
                          controller.currentLoadingTip.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
                        )),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildTag(String text) {
    return Obx(() => GestureDetector(
      onTap: controller.isLoading.value ? null : () {
        controller.promptController.text = text;
        // Don't auto-generate, let user press Enter or click arrow
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ),
    ));
  }
}

// Small animated logo used in loading overlay
class _LoadingLogo extends StatefulWidget {
  @override
  State<_LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<_LoadingLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: const Center(
          child: Icon(Icons.auto_awesome, color: Color(0xFF2C3E50), size: 44),
        ),
      ),
    );
  }
}

// Small feature chip used in header
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // match app background (usually white)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Animated three dots
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = (_ctrl.value * 3).floor();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final active = (i == t % 3);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: active ? 12 : 8,
                height: active ? 12 : 8,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white70,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create a wave-like shape starting from the left
    path.moveTo(0, size.height * 0.3);
    
    // First curve
    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.2,
      size.width * 0.4, size.height * 0.3,
    );
    
    // Second curve
    path.quadraticBezierTo(
      size.width * 0.6, size.height * 0.4,
      size.width * 0.8, size.height * 0.3,
    );
    
    // Final curve to bottom right
    path.quadraticBezierTo(
      size.width, size.height * 0.2,
      size.width, size.height,
    );
    
    // Complete the shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}