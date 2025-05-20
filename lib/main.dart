import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/body_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/library_screen.dart';

void main() {
  runApp(const FitnessMiniApp());
}

class FitnessMiniApp extends StatelessWidget {
  const FitnessMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健身助手',
      theme: buildAppTheme(),
      home: const MainScreen(),
      routes: {
        '/body': (context) => const BodyScreen(),
        '/workout': (context) => const WorkoutScreen(),
        '/nutrition': (context) => const NutritionScreen(),
        '/library': (context) => const LibraryScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // 底部导航栏对应的页面
  final List<Widget> _screens = [
    const DashboardScreen(),
    const BodyScreen(),
    const WorkoutScreen(),
    const NutritionScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: '体测',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '训练',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: '饮食',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '资源',
          ),
        ],
      ),
    );
  }
}
