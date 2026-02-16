import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/infographic_viewer/bindings/infographic_viewer_binding.dart';
import '../modules/infographic_viewer/views/infographic_viewer_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.INFOGRAPHIC_VIEWER,
      page: () => const InfographicViewerView(),
      binding: InfographicViewerBinding(),
    ),
  ];
}
