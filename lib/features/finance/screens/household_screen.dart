import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/app_card.dart';
import '../data/finance_repository.dart';
import '../data/models.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({required this.repository, required this.activeHouseholdId, required this.onChanged, super.key});
  final FinanceRepository repository;
  final String? activeHouseholdId;
  final Future<void> Function() onChanged;
  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final _householdName = TextEditingController();
  final _email = TextEditingController();
  late Future<_HouseholdData> _future;
  String _role = 'member';
  bool _busy = false;
  String? _message;
  String? _error;
  @override
  void initState() { super.initState(); _future = _load(); }
  @override
  void dispose() { _householdName.dispose(); _email.dispose(); super.dispose(); }
  Future<_HouseholdData> _load() async {
    final pending = await widget.repository.pendingInvites();
    final households = await widget.repository.households();
    final selected = households.where((item) => item.id == widget.activeHouseholdId).firstOrNull;
    if (selected == null) return _HouseholdData(households, pending, const [], const []);
    final values = await Future.wait([widget.repository.householdMembers(selected.id), widget.repository.householdInvites(selected.id)]);
    return _HouseholdData(households, pending, values[0] as List<HouseholdMemberInfo>, values[1] as List<HouseholdInvite>);
  }
  void _refresh() { setState(() { _message = null; _error = null; _future = _load(); }); }

  Future<void> _createHousehold() async {
    if (_householdName.text.trim().isEmpty) { setState(() => _error = 'Nhập tên household.'); return; }
    await _run(() async { await widget.repository.createHousehold(_householdName.text.trim()); _householdName.clear(); await widget.onChanged(); _message = 'Đã tạo household. Chọn household đó ở bộ chuyển phía trên để xem tài chính chung.'; });
  }

  Future<void> _invite(String householdId) async {
    final email = _email.text.trim();
    if (!email.contains('@')) { setState(() => _error = 'Nhập địa chỉ email hợp lệ.'); return; }
    await _run(() async { await widget.repository.inviteMember(householdId, email, _role); _email.clear(); _message = 'Đã tạo lời mời cho $email.'; });
  }

  Future<void> _accept(HouseholdInvite invite) async {
    await _run(() async { await widget.repository.acceptInvite(invite.id); await widget.onChanged(); _message = 'Đã tham gia ${invite.householdName ?? 'household'}.'; });
  }

  Future<void> _leave(HouseholdInfo household) async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Rời household?'), content: Text('Bạn sẽ mất quyền truy cập vào ${household.name}.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ở lại')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Rời nhóm'))]));
    if (yes != true) return;
    await _run(() async { await widget.repository.leaveHousehold(household.id); await widget.onChanged(); _message = 'Đã rời household.'; });
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() { _busy = true; _error = null; _message = null; });
    try { await task(); if (mounted) setState(() { _busy = false; _future = _load(); }); }
    catch (error) { if (mounted) setState(() { _busy = false; _error = error.toString().replaceFirst('Exception: ', ''); }); }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_HouseholdData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Không thể tải household: ${snapshot.error}'));
          final data = snapshot.data!;
          final active = data.households.where((item) => item.id == widget.activeHouseholdId).firstOrNull;
          return ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 30), children: [
            Text('Household', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text('Chia sẻ ví và theo dõi tài chính cùng gia đình', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
            if (data.pending.isNotEmpty) ...[
              const SizedBox(height: 20),
              const SectionTitle('Lời mời đang chờ'),
              ...data.pending.map((invite) => AppCard(margin: const EdgeInsets.only(top: 8), child: Row(children: [Expanded(child: Text('${invite.householdName ?? 'Household'} · ${invite.role}')), FilledButton(onPressed: _busy ? null : () => _accept(invite), child: const Text('Chấp nhận'))]))),
            ],
            const SizedBox(height: 20),
            if (active == null) ...[
              const SectionTitle('Tạo household mới'),
              AppCard(child: Column(children: [TextField(controller: _householdName, decoration: const InputDecoration(labelText: 'Tên household', prefixIcon: Icon(Icons.home_outlined))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _createHousehold, icon: const Icon(Icons.add_rounded), label: const Text('Tạo household')))])),
              const SizedBox(height: 18),
              const SectionTitle('Household của bạn'),
              if (data.households.isEmpty) const AppCard(child: EmptyState(icon: Icons.group_outlined, title: 'Bạn chưa tham gia household', message: 'Tạo household hoặc chấp nhận lời mời để chia sẻ tài chính.')),
              ...data.households.map((item) => AppCard(margin: const EdgeInsets.only(top: 8), child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.home_work_outlined), title: Text(item.name), subtitle: Text(item.role.name), trailing: const Icon(Icons.check_circle_outline_rounded)))),
            ] else ...[
              AppCard(child: Row(children: [CircleAvatar(child: const Icon(Icons.home_work_outlined, color: Colors.white), backgroundColor: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(active.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), Text('Vai trò: ${_roleName(active.role)}', style: Theme.of(context).textTheme.bodySmall)])), if (active.role != HouseholdRole.owner) IconButton(tooltip: 'Rời household', onPressed: _busy ? null : () => _leave(active), icon: const Icon(Icons.logout_rounded))])),
              if (active.role == HouseholdRole.owner || active.role == HouseholdRole.admin) ...[
                const SizedBox(height: 18),
                const SectionTitle('Mời thành viên'),
                AppCard(child: Column(children: [TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email thành viên', prefixIcon: Icon(Icons.email_outlined))), const SizedBox(height: 10), Row(children: [Expanded(child: DropdownButtonFormField<String>(value: _role, decoration: const InputDecoration(labelText: 'Quyền'), items: const [DropdownMenuItem(value: 'member', child: Text('Thành viên')), DropdownMenuItem(value: 'admin', child: Text('Quản trị viên'))], onChanged: (value) => setState(() => _role = value!))), const SizedBox(width: 10), FilledButton(onPressed: _busy ? null : () => _invite(active.id), child: const Text('Gửi lời mời'))])])),
              ],
              const SizedBox(height: 18),
              const SectionTitle('Thành viên'),
              AppCard(child: data.members.isEmpty ? const Text('Chưa tải được danh sách thành viên.') : Column(children: data.members.map((member) => ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)), title: Text(member.userId == Supabase.instance.client.auth.currentUser?.id ? 'Bạn' : '${member.userId.substring(0, 8)}…'), subtitle: Text('${_roleName(householdRoleFrom(member.role))} · ${member.joinedAt.substring(0, 10)}'))).toList())),
              const SizedBox(height: 18),
              const SectionTitle('Lời mời gửi đi'),
              AppCard(child: data.invitations.isEmpty ? const Text('Chưa có lời mời.') : Column(children: data.invitations.map((invite) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.mail_outline_rounded), title: Text(invite.email), subtitle: Text('${invite.role} · ${invite.status}'))).toList())),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _busy ? null : _refresh, icon: const Icon(Icons.refresh_rounded), label: const Text('Làm mới')),
          ]);
        },
      );
}

class _HouseholdData {
  const _HouseholdData(this.households, this.pending, this.members, this.invitations);
  final List<HouseholdInfo> households;
  final List<HouseholdInvite> pending;
  final List<HouseholdMemberInfo> members;
  final List<HouseholdInvite> invitations;
}

String _roleName(HouseholdRole role) => switch (role) { HouseholdRole.owner => 'Chủ sở hữu', HouseholdRole.admin => 'Quản trị viên', HouseholdRole.member => 'Thành viên' };
