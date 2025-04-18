import 'package:flutter/material.dart';
import 'asset.dart';
import 'database/asset_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the database when the app starts
  await AssetDatabase.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Finance Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to Finance Tracker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            _buildMenuButton(context, 'Asset', Icons.account_balance, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssetMenu()),
              );
            }),
            const SizedBox(height: 16),
            _buildMenuButton(context, 'Depreciation', Icons.trending_down, () {
              // Navigation will be implemented later
            }),
            const SizedBox(height: 16),
            _buildMenuButton(context, 'Monthly Tracker', Icons.calendar_today, () {
              // Navigation will be implemented later
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        minimumSize: const Size(240, 60),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
