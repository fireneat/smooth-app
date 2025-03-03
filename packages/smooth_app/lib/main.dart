import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:openfoodfacts/personalized_search/product_preferences_selection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:smooth_app/data_models/continuous_scan_model.dart';
import 'package:smooth_app/data_models/product_preferences.dart';
import 'package:smooth_app/data_models/up_to_date_product_provider.dart';
import 'package:smooth_app/data_models/user_management_provider.dart';
import 'package:smooth_app/data_models/user_preferences.dart';
import 'package:smooth_app/database/dao_string.dart';
import 'package:smooth_app/database/local_database.dart';
import 'package:smooth_app/helpers/analytics_helper.dart';
import 'package:smooth_app/helpers/camera_helper.dart';
import 'package:smooth_app/helpers/data_importer/smooth_app_data_importer.dart';
import 'package:smooth_app/helpers/network_config.dart';
import 'package:smooth_app/helpers/permission_helper.dart';
import 'package:smooth_app/pages/onboarding/onboarding_flow_navigator.dart';
import 'package:smooth_app/query/product_query.dart';
import 'package:smooth_app/services/smooth_services.dart';
import 'package:smooth_app/themes/smooth_theme.dart';
import 'package:smooth_app/themes/theme_provider.dart';
import 'package:smooth_app/widgets/smooth_scaffold.dart';

late bool _screenshots;

Future<void> main({final bool screenshots = false}) async {
  _screenshots = screenshots;
  if (_screenshots) {
    await _init1();
    runApp(const SmoothApp());
    return;
  }
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (kReleaseMode) {
    await AnalyticsHelper.initSentry(
      appRunner: () => runApp(const SmoothApp()),
    );
  } else {
    runApp(
      DevicePreview(
        enabled: true,
        builder: (_) => const SmoothApp(),
      ),
    );
  }
}

class SmoothApp extends StatefulWidget {
  const SmoothApp();

  // This widget is the root of your application
  @override
  State<SmoothApp> createState() => _SmoothAppState();
}

late SmoothAppDataImporter _appDataImporter;
late UserPreferences _userPreferences;
late ProductPreferences _productPreferences;
late LocalDatabase _localDatabase;
late ThemeProvider _themeProvider;
final ContinuousScanModel _continuousScanModel = ContinuousScanModel();
final PermissionListener _permissionListener =
    PermissionListener(permission: Permission.camera);
final UpToDateProductProvider _upToDateProductProvider =
    UpToDateProductProvider();
bool _init1done = false;

// Had to split init in 2 methods, for test/screenshots reasons.
// Don't know why, but some init codes seem to freeze the test.
// Now we run them before running the app, during the tests.
Future<bool> _init1() async {
  if (_init1done) {
    return false;
  }

  await SmoothServices().init();
  await setupAppNetworkConfig();
  await UserManagementProvider.mountCredentials();
  _userPreferences = await UserPreferences.getUserPreferences();
  _localDatabase = await LocalDatabase.getLocalDatabase();
  _appDataImporter = SmoothAppDataImporter(_localDatabase);
  await _continuousScanModel.load(_localDatabase);
  _productPreferences = ProductPreferences(
    ProductPreferencesSelection(
      setImportance: _userPreferences.setImportance,
      getImportance: _userPreferences.getImportance,
      notify: () => _productPreferences.notifyListeners(),
    ),
    daoString: DaoString(_localDatabase),
  );

  AnalyticsHelper.setCrashReports(_userPreferences.crashReports);
  ProductQuery.setCountry(_userPreferences.userCountryCode);
  _themeProvider = ThemeProvider(_userPreferences);
  ProductQuery.setQueryType(_userPreferences);

  await CameraHelper.init();
  await ProductQuery.setUuid(_localDatabase);
  _init1done = true;
  return true;
}

class _SmoothAppState extends State<SmoothApp> {
  final UserManagementProvider _userManagementProvider =
      UserManagementProvider();

  bool systemDarkmodeOn = false;
  final Brightness brightness =
      SchedulerBinding.instance.window.platformBrightness;

  // We store the argument of FutureBuilder to avoid re-initialization on
  // subsequent builds. This enables hot reloading. See
  // https://github.com/openfoodfacts/smooth-app/issues/473
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _init2();
  }

  Future<bool> _init2() async {
    await _init1();
    systemDarkmodeOn = brightness == Brightness.dark;
    if (!mounted) {
      return false;
    }
    await _productPreferences.init(DefaultAssetBundle.of(context));
    await AnalyticsHelper.initMatomo(_screenshots);
    if (!_screenshots) {
      await _userPreferences.init(_productPreferences);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.hasError) {
          FlutterNativeSplash.remove();
          return _buildError(snapshot);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          //We don't need a loading indicator since the splash screen is still visible
          return Container();
        }

        // The `create` constructor of [ChangeNotifierProvider] takes care of
        // disposing the value.
        ChangeNotifierProvider<T> provide<T extends ChangeNotifier>(T value) =>
            ChangeNotifierProvider<T>(create: (BuildContext context) => value);

        if (!_screenshots) {
          // ending FlutterNativeSplash.preserve()
          FlutterNativeSplash.remove();
        }

        return MultiProvider(
          providers: <ChangeNotifierProvider<ChangeNotifier>>[
            provide<UserPreferences>(_userPreferences),
            provide<ProductPreferences>(_productPreferences),
            provide<LocalDatabase>(_localDatabase),
            provide<ThemeProvider>(_themeProvider),
            provide<UserManagementProvider>(_userManagementProvider),
            provide<ContinuousScanModel>(_continuousScanModel),
            provide<SmoothAppDataImporter>(_appDataImporter),
            provide<UpToDateProductProvider>(_upToDateProductProvider),
            provide<PermissionListener>(_permissionListener),
            provide<CameraControllerNotifier>(
                CameraHelper.cameraControllerNotifier),
          ],
          builder: _buildApp,
        );
      },
    );
  }

  Widget _buildApp(BuildContext context, Widget? child) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final OnboardingPage lastVisitedOnboardingPage =
        _userPreferences.lastVisitedOnboardingPage;
    final Widget appWidget = OnboardingFlowNavigator(_userPreferences)
        .getPageWidget(context, lastVisitedOnboardingPage);
    final bool isOnboardingComplete =
        OnboardingFlowNavigator.isOnboardingComplete(lastVisitedOnboardingPage);
    themeProvider.setOnboardingComplete(isOnboardingComplete);
    final String? languageCode =
        context.select((UserPreferences up) => up.appLanguageCode);

    return MaterialApp(
      locale: languageCode != null ? Locale(languageCode) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: !(kReleaseMode || _screenshots),
      navigatorObservers: <NavigatorObserver>[
        SentryNavigatorObserver(),
      ],
      theme: SmoothTheme.getThemeData(
        Brightness.light,
        themeProvider,
      ),
      darkTheme: SmoothTheme.getThemeData(
        Brightness.dark,
        themeProvider,
      ),
      themeMode: themeProvider.currentThemeMode,
      home: SmoothAppGetLanguage(appWidget),
    );
  }

  Widget _buildError(AsyncSnapshot<void> snapshot) {
    return MaterialApp(
      home: SmoothScaffold(
        body: Center(
          child: Text(
            'Fatal Error: ${snapshot.error}',
          ),
        ),
      ),
    );
  }
}

/// Layer needed because we need to know the language. Language isn't available
/// in the [context] in top level widget ([SmoothApp])
class SmoothAppGetLanguage extends StatelessWidget {
  const SmoothAppGetLanguage(this.appWidget);

  final Widget appWidget;

  @override
  Widget build(BuildContext context) {
    // TODO(monsieurtanuki): refactor removing the `SmoothAppGetLanguage` layer?
    // will refresh each time the language changes
    context.select(
      (final UserPreferences userPreferences) =>
          userPreferences.appLanguageCode,
    );
    final String languageCode = Localizations.localeOf(context).languageCode;
    ProductQuery.setLanguage(languageCode);
    context.read<ProductPreferences>().refresh(languageCode);

    // The migration requires the language to be set in the app
    _appDataImporter.startMigrationAsync();

    return appWidget;
  }
}
