import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.themeMode, required this.onThemeChanged, super.key});
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          Text('Cài đặt', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text('Tùy chỉnh trải nghiệm MyFinance', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          const SectionTitle('Giao diện'),
          AppCard(
            padding: EdgeInsets.zero,
            child: RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (mode) {
                if (mode != null) onThemeChanged(mode);
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    secondary: Icon(Icons.settings_suggest_outlined),
                    title: Text('Theo thiết bị'),
                    subtitle: Text('Tự đổi theo cài đặt của hệ điều hành'),
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    secondary: Icon(Icons.light_mode_outlined),
                    title: Text('Sáng'),
                    subtitle: Text('Giao diện nền sáng'),
                  ),
                  Divider(height: 1),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    secondary: Icon(Icons.dark_mode_outlined),
                    title: Text('Tối'),
                    subtitle: Text('Giao diện nền tối'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Dữ liệu'),
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tài khoản và dữ liệu tài chính được lưu trong Supabase, giống bản web MyFinance. Quyền truy cập được kiểm soát bằng chính sách RLS của cơ sở dữ liệu.',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
