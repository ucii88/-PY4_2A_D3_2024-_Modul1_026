import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app/services/mongo_service.dart';
import 'package:logbook_app/services/connectivity_service.dart';
import 'package:logbook_app/helpers/log_helper.dart';
import 'package:logbook_app/features/onboarding/onboarding_view.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await ConnectivityService().initialize();

  try {
    await dotenv.load(fileName: ".env");
    print('✅ [main] .env file loaded');

    // INISIALISASI HIVE - STRICT ERROR HANDLING
    print('[main] Starting Hive initialization...');

    await Hive.initFlutter();
    print('✅ [main] Hive.initFlutter() completed');

    print('[main] Registering LogModelAdapter...');
    Hive.registerAdapter(LogModelAdapter());
    print('✅ [main] LogModelAdapter registered');

    print('[main] Opening offline_logs box...');
    try {
      await Hive.openBox<LogModel>('offline_logs');
      print('✅ [main] Hive.openBox("offline_logs") completed');
    } catch (e) {
      print(
        '⚠️ [main] Box corrupted or incompatible, clearing and recreating...',
      );
      try {
        await Hive.deleteBoxFromDisk('offline_logs');
        print('✅ [main] Deleted corrupted box from disk');
      } catch (deleteError) {
        print(
          '⚠️ [main] Could not delete box: $deleteError, attempting to open anyway...',
        );
      }
      // Wait a moment before retrying
      await Future.delayed(const Duration(milliseconds: 500));
      await Hive.openBox<LogModel>('offline_logs');
      print('✅ [main] Hive box opened/recreated');
    }

    print('✅ [main] Hive initialized with offline_logs box');

    await LogHelper.initialize();
    print('✅ [main] Logs directory initialized');

    await MongoService().connect();
    print('✅ [main] MongoDB connected');
  } catch (e, stackTrace) {
    print('❌ [main] Initialization failed: $e');
    print('❌ [main] Stack trace: $stackTrace');
    rethrow; // Let error propagate so we can see it
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
