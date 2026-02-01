import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/bindings/general_bindings.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/constants/text_strings.dart';
import 'package:rps_stationery/utils/theme/app_theme.dart';
import 'package:rps_stationery/utils/error_boundary/error_boundary.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      fallbackTitle: 'App Error',
      fallbackMessage: 'Something went wrong with the app. Please restart the application.',
      child: GetMaterialApp(
        title: TTexts.appName,
        themeMode: ThemeMode.system, // Default theme, will be updated by ThemeController
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        initialBinding: GeneralBindings(),
        getPages: AppPages.routes,
        // Remove home to let AuthRepository handle initial routing
        unknownRoute: GetPage(
          name: '/unknown',
          page: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}


