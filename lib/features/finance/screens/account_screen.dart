import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_card.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({required this.onNavigate, super.key});
  final ValueChanged<String> onNavigate;
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Tài khoản';
    final name = user?.userMetadata?['full_name']?.toString().trim();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 30), children: [
      Text('Tài khoản', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      AppCard(child: Row(children: [CircleAvatar(radius: 26, backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, child: Text((name?.isNotEmpty == true ? name![0] : email[0]).toUpperCase())), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name?.isNotEmpty == true ? name! : email.split('@').first, style: const TextStyle(fontWeight: FontWeight.w800)), Text(email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))]))])),
      const SizedBox(height: 18),
      Text('QUẢN LÝ TÀI CHÍNH', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1)),
      const SizedBox(height: 6),
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        _item(context, Icons.sell_outlined, 'Danh mục', 'Quản lý danh mục thu và chi', 'categories'),
        const Divider(height: 1),
        _item(context, Icons.bar_chart_rounded, 'Báo cáo', 'Xem phân tích tài chính', 'reports'),
        const Divider(height: 1),
        _item(context, Icons.group_outlined, 'Household', 'Quản lý tài chính chung', 'household'),
      ])),
      const SizedBox(height: 18),
      Text('ỨNG DỤNG', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1)),
      const SizedBox(height: 6),
      AppCard(padding: EdgeInsets.zero, child: _item(context, Icons.settings_outlined, 'Cài đặt', 'Giao diện và tùy chọn', 'settings')),
      const SizedBox(height: 18),
      OutlinedButton.icon(onPressed: () async { await Supabase.instance.client.auth.signOut(); }, icon: const Icon(Icons.logout_rounded), label: const Text('Đăng xuất')),
      const SizedBox(height: 14),
      Center(child: Text('MyFinance · VND', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
    ]);
  }

  Widget _item(BuildContext context, IconData icon, String title, String subtitle, String page) => ListTile(leading: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => onNavigate(page));
}
