import 'package:flutter/material.dart';
import 'flavor/app_flavor.dart';
import 'flavor/flavor_config.dart';
import 'flavor/flavor_platform.dart';
import 'flavor/flavor_values.dart';
import 'screens/admin_login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/route_observer.dart';
import 'utils/storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final flavor = await FlavorPlatform.getFlavor();
  late AppFlavor appFlavor;
  late FlavorValues values;
  switch (flavor) {
    case 'lordsChurchAdmin':
      appFlavor = AppFlavor.lordsChurchAdmin;
      values = const FlavorValues(
        appName: "TLC Admin",
        logoAsset: "assets/images/lordsChurch.jpg",
        primaryColor: Colors.black,
        fontFamily: 'Roboto',
      );
      break;
    default:
      appFlavor = AppFlavor.lordsChurchAdmin;
      values = const FlavorValues(
        appName: "Lords Church Admin",
        logoAsset: "assets/images/lordsChurch.jpg",
        primaryColor: Colors.black,
        fontFamily: 'Roboto',
      );
  }
  FlavorConfig.init(flavor: appFlavor, values: values);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: FutureBuilder(
        future: Storage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AdminLoginScreen();
          }
          return const DashboardScreen();
        },
      ),
    );
  }
}
