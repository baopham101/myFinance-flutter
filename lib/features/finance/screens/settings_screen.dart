import 'package:flutter/material.dart';

import '../../../core/widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.themeMode, required this.onThemeChanged, super.key});
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 30), children: [
    Text('Cài đặt', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
    Text('Tùy chỉnh trải nghiệm MyFinance', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    const SizedBox(height: 18),
    const SectionTitle('Giao diện'),
    AppCard(padding: EdgeInsets.zero, child: Column(children: [
      _themeOption(context, ThemeMode.system, 'Theo thiết bị', 'Tự đổi theo cài đặt của hệ điều hành', Icons.settings_suggest_outlined),
      const Divider(height: 1),
      _themeOption(context, ThemeMode.light, 'Sáng', 'Giao diện nền sáng', Icons.light_mode_outlined),
      const Divider(height: 1),
      _themeOption(context, ThemeMode.dark, 'Tối', 'Giao diện nền tối', Icons.dark_mode_outlined),
    ])),
    const SizedBox(height: 16),
    const SectionTitle('Dữ liệu'),
    const AppCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lock_outline_rounded), SizedBox(width: 12), Expanded(child: Text('Tài khoản và dữ liệu tài chính được lưu trong Supabase, giống bản web MyFinance. Quyền truy cập được kiểm soát bằng chính sách RLS của cơ sở dữ liệu.'))])),
  ]);

  Widget _themeOption(BuildContext context, ThemeMode value, String title, String subtitle, IconData icon) => RadioListTile<ThemeMode>(value: value, groupValue: themeMode, onChanged: (mode) { if (mode != null) onThemeChanged(mode); }, secondary: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title), subtitle: Text(subtitle));
}
