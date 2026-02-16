
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infography/app/data/services/remote-config-service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  // Make sure bindings are initialized before using async
  WidgetsFlutterBinding.ensureInitialized();

  // Api Key Package Initialization


  //  Await Firebase initialization
  await Firebase.initializeApp();

  //  Await Remote Config initialization
  await RemoteConfigService().initialize();

  // Firebase Analytics instance
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  runApp(
    GetMaterialApp(
      title: "Infographic Generator",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorObservers: [observer],
    ),
  );
}
