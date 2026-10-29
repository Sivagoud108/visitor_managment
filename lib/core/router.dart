import 'package:go_router/go_router.dart';
import 'package:visitor_management/core/route.dart';
import 'package:visitor_management/screens/dashboard_screen.dart';
import 'package:visitor_management/screens/main_shell.dart';
import 'package:visitor_management/screens/scanner_screen.dart';
import 'package:visitor_management/screens/visitor_register_screen.dart';
import 'package:visitor_management/screens/visitor_list_screen.dart';
final appRouter = GoRouter(
  initialLocation: Routes.mainShell,
  routes: [
    GoRoute(path: Routes.visitorList, builder: (context, state) => const VisitorListScreen()),
    GoRoute(path: Routes.mainShell, builder: (context, state) => const MainShell()),
    GoRoute(path: Routes.dashboard, builder: (context, state) => const DashboardScreen()),
    GoRoute(path: Routes.register, builder: (context, state) => const VisitorRegisterScreen()),
    GoRoute(path: Routes.scanner, builder: (context, state) => const ScannerScreen()),
  
  ]);