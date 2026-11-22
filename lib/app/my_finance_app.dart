import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_gate.dart';

class MyFinanceApp extends StatefulWidget {
  const MyFinanceApp({this.initializationError, super.key});
  final String? initializationError;

  @override
  State<MyFinanceApp> createState() => _MyFinanceAppState();
}

class _MyFinanceAppState extends State<MyFinanceApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (!mounted) return;
    setState(() {
      _themeMode = ThemeMode.values.firstWhere((mode) => mode.name == saved, orElse: () => ThemeMode.system);
      _loaded = true;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MyFinance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode,
        home: !_loaded
            ? const _SplashScreen()
            : widget.initializationError != null
                ? _ConfigurationScreen(error: widget.initializationError!)
                : !AppConfig.isConfigured
                    ? const _ConfigurationScreen()
                    : AuthGate(themeMode: _themeMode, onThemeChanged: _setTheme),
      );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ConfigurationScreen extends StatelessWidget {
  const _ConfigurationScreen({this.error});
  final String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.account_balance_wallet_rounded, size: 44, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 18),
                Text('Cần cấu hình Supabase', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('Ứng dụng Flutter dùng chung dữ liệu và tài khoản với MyFinance Web. Hãy truyền URL và anon key của dự án Supabase khi chạy.'),
                const SizedBox(height: 16),
                const SelectableText('flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>'),
                const SizedBox(height: 12),
                const Text('Lấy hai giá trị này từ cấu hình .env.local của bản web; không dùng service role key.'),
                if (error != null) ...[const SizedBox(height: 12), SelectableText('Lỗi khởi tạo Supabase: $error')],
              ]),
            ),
          ),
        ),
      );
}
