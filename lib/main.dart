import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/dashboard_provider.dart';
import 'services/firestore_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/reports/add_report_screen.dart';
import 'screens/reports/advanced_reports_screen.dart';
import 'screens/security/security_monitor_screen.dart';
import 'screens/security/security_settings_screen.dart';
import 'screens/security/threat_management_screen.dart';
import 'screens/ai/ai_prediction_screen.dart';
import 'screens/notifications/smart_notifications_screen.dart';
import 'screens/maps/3d_maps_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/driving/driving_mode_screen.dart';
import 'theme/enhanced_theme.dart';
import 'utils/performance_utils.dart';
import 'utils/network_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize performance monitoring
  PerformanceMonitor.startPeriodicReporting();
  MemoryOptimizer.startPeriodicCleanup();
  
  // Initialize network manager
  NetworkManager().initialize();
  BandwidthMonitor().startMonitoring();
  
  // Warm up shaders for better performance
  PerformanceUtils.warmUpShaders();
  
  runApp(const SafeRouteApp());
}

class SafeRouteApp extends StatelessWidget {
  const SafeRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => ReportsProvider(
            firestoreService: FirestoreService(),
            locationService: LocationService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'SafeRoute',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', 'SA'), // Arabic
              Locale('en', 'US'), // English
            ],
            locale: const Locale('ar', 'SA'),
            theme: EnhancedTheme.lightTheme.copyWith(
              extensions: [CustomColors.light],
            ),
            darkTheme: EnhancedTheme.darkTheme.copyWith(
              extensions: [CustomColors.dark],
            ),
            themeMode: ThemeMode.system,
            home: NetworkAwareWidget(
              child: FutureBuilder(
                future: authProvider.initialize(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  return authProvider.isAuthenticated 
                      ? const DashboardScreen() 
                      : const LoginScreen();
                },
              ),
            ),
            routes: {
              '/login': (context) => const NetworkAwareWidget(
                child: LoginScreen(),
              ),
              '/register': (context) => const NetworkAwareWidget(
                child: RegisterScreen(),
              ),
              '/dashboard': (context) => const NetworkAwareWidget(
                child: DashboardScreen(),
              ),
              '/home': (context) => const NetworkAwareWidget(
                child: HomeScreen(),
              ),
              '/add-report': (context) => const NetworkAwareWidget(
                child: AddReportScreen(),
              ),
              '/profile': (context) => const NetworkAwareWidget(
                child: ProfileScreen(),
              ),
              '/driving-mode': (context) => const NetworkAwareWidget(
                child: DrivingModeScreen(),
              ),
              '/advanced-reports': (context) => const NetworkAwareWidget(
                child: AdvancedReportsScreen(),
              ),
        '/security-monitor': (context) => const NetworkAwareWidget(
          child: SecurityMonitorScreen(),
        ),
        '/security-settings': (context) => const NetworkAwareWidget(
          child: SecuritySettingsScreen(),
        ),
        '/threat-management': (context) => const NetworkAwareWidget(
          child: ThreatManagementScreen(),
        ),
        '/ai-prediction': (context) => NetworkAwareWidget(
            child: const AIPredictionScreen(),
          ),
          '/smart-notifications': (context) => NetworkAwareWidget(
            child: const SmartNotificationsScreen(),
          ),
          '/3d-maps': (context) => NetworkAwareWidget(
            child: const Maps3DScreen(),
          ),
            },
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
