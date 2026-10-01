import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/inventario_provider.dart';
import 'providers/finanzas_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
        ChangeNotifierProvider(create: (_) => FinanzasProvider()),
      ],
      child: MaterialApp(
        title: 'Atelier',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEC6294)),
          useMaterial3: true,
          fontFamily: 'PlusJakartaSans',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
