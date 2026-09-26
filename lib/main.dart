import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/inventario_provider.dart';
import 'screens/main_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Mi Emprendimiento',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEC6294)),
          useMaterial3: true,
          fontFamily: 'Roboto', // Ajustable según necesidad
        ),
        home: const MainScreen(),
      ),
    );
  }
}
