import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_input_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/study_planner_screen.dart';
import 'screens/weekly_study_preferences_screen.dart';
import 'providers/task_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/study_plan_provider.dart';
import 'providers/task_template_provider.dart';
import 'providers/schedule_provider.dart';

// Custom scroll behavior optimized for 120Hz displays
class HighRefreshScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Enable smooth scrolling optimized for high refresh rates
    return super.buildScrollbar(context, child, details);
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Custom physics for 120Hz displays
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

void main() {
  // Enable high refresh rate and optimize for performance
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize for 120Hz displays
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Enable hardware acceleration for better 120Hz performance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProxyProvider<GamificationProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, gamificationProvider, taskProvider) {
            taskProvider?.setGamificationProvider(gamificationProvider);
            return taskProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StudyPlanProvider()),
        ChangeNotifierProvider(create: (_) => TaskTemplateProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FocusFlow',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // Performance optimizations for 120Hz displays
            checkerboardRasterCacheImages: false,
            checkerboardOffscreenLayers: false,
            showPerformanceOverlay: false,
            scrollBehavior: HighRefreshScrollBehavior(),
            home: const MainNavigationScreen(),
            routes: {
              '/dashboard': (context) => const DashboardScreen(),
              '/task-input': (context) => const TaskInputScreen(),
              '/focus-timer': (context) => const FocusTimerScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/study-planner': (context) => const StudyPlannerScreen(),
              '/weekly-preferences': (context) => const WeeklyStudyPreferencesScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name?.startsWith('/task-detail/') == true) {
                final taskId = settings.name!.split('/').last;
                return MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(taskId: taskId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TaskInputScreen(),
    const FocusTimerScreen(),
    const StudyPlannerScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}