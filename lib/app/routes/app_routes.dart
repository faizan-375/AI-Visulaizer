part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const INFOGRAPHIC_VIEWER = _Paths.INFOGRAPHIC_VIEWER;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const INFOGRAPHIC_VIEWER = '/infographic-viewer';
}
