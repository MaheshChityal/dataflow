import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/template_service.dart';
import 'services/pipeline_service.dart';
import 'services/master_data_service.dart';
import 'providers/auth_provider.dart';
import 'providers/template_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  // Create shared API service instance
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        // Services (singleton, not ChangeNotifier — use Provider.value or ProxyProvider)
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>(create: (_) => AuthService(apiService)),
        Provider<TemplateService>(create: (_) => TemplateService(apiService)),
        Provider<PipelineService>(create: (_) => PipelineService(apiService)),
        Provider<MasterDataService>(create: (_) => MasterDataService(apiService)),

        // Providers (ChangeNotifier)
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<AuthService>()),
          update: (_, authService, prev) => prev ?? AuthProvider(authService),
        ),
        ChangeNotifierProxyProvider<TemplateService, TemplateProvider>(
          create: (ctx) => TemplateProvider(ctx.read<TemplateService>()),
          update: (_, templateService, prev) => prev ?? TemplateProvider(templateService),
        ),
      ],
      child: const PipelineApp(),
    ),
  );
}

class PipelineApp extends StatelessWidget {
  const PipelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HDFC Pipeline Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'DM Sans',
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
