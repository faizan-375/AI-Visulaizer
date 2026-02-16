import 'package:get/get.dart';
import '../controllers/infographic_viewer_controller.dart';

class InfographicViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InfographicViewerController>(
      () => InfographicViewerController(),
    );
  }
}
