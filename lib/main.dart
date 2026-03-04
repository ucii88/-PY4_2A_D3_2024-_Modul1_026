import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app/services/mongo_service.dart';
import 'package:logbook_app/services/connectivity_service.dart';
import 'package:logbook_app/helpers/log_helper.dart';
import 'package:logbook_app/features/onboarding/onboarding_view.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await ConnectivityService().initialize();

  try {
    await dotenv.load(fileName: ".env");
    print('✅ [main] .env file loaded');

    await LogHelper.initialize();
    print('✅ [main] Logs directory initialized');

    await MongoService().connect();
    print('✅ [main] MongoDB connected');
  } catch (e) {
    print('❌ [main] Initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LogBook App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OnboardingView(),
    );
  }
}
