import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/app_card.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      final client = Supabase.instance.client;
      if (_register) {
        final response = await client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (response.session == null) {
          _notice = 'Tài khoản đã được tạo. Hãy kiểm tra email để xác nhận rồi đăng nhập.';
        }
      } else {
        await client.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'Không thể kết nối. Hãy thử lại. ($error)';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Nhập email trước khi đặt lại mật khẩu.');
      return;
    }
    setState(() { _busy = true; _error = null; _notice = null; });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _notice = 'Đã gửi liên kết đặt lại mật khẩu tới $email.';
    } on AuthException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Không thể gửi email đặt lại mật khẩu.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Image.asset('assets/appLogo.png', height: 42, width: 42),
                    const SizedBox(height: 12),
                    Text('Money Keeper', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(_register ? 'Tạo tài khoản để quản lý tài chính' : 'Đăng nhập để tiếp tục', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    if (_register) ...[
                      TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Tên hiển thị', prefixIcon: Icon(Icons.person_outline))),
                      const SizedBox(height: 12),
                    ],
                    TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                    const SizedBox(height: 12),
                    TextField(controller: _password, obscureText: true, autofillHints: _register ? const [AutofillHints.newPassword] : const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline))),
                    if (!_register) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : _resetPassword, child: const Text('Quên mật khẩu?'))),
                    if (_error != null) ...[const SizedBox(height: 10), ErrorMessage(_error!)],
                    if (_notice != null) ...[const SizedBox(height: 10), Text(_notice!, style: TextStyle(color: Theme.of(context).colorScheme.primary))],
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_register ? 'Tạo tài khoản' : 'Đăng nhập')),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; _notice = null; }), child: Text(_register ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
