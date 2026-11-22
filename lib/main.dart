import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/my_finance_app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initializationError;
  if (AppConfig.isConfigured) {
    try {
      await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey);
    } catch (error) {
      initializationError = error.toString();
    }
  }
  runApp(MyFinanceApp(initializationError: initializationError));
}
