// ผู้รับผิดชอบ: สมาชิกคนที่ 3 (ระบบสมาชิก)
// หน้าสมัครสมาชิก (สมัครได้เฉพาะ role user แอดมินมาจากข้อมูลตั้งต้น)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/feedback.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthProvider>().register(_username.text, _password.text);
      // สมัครสำเร็จ = ล็อกอินแล้ว ปิดหน้านี้เพื่อให้เห็นหน้าแรก
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) showError(context, e.message);
    } catch (e) {
      if (mounted) showError(context, 'สมัครไม่สำเร็จ: $e', onRetry: _submit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้', prefixIcon: Icon(Icons.person)),
              validator: AuthProvider.validateUsername,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'รหัสผ่าน', prefixIcon: Icon(Icons.lock)),
              validator: AuthProvider.validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่าน', prefixIcon: Icon(Icons.lock_outline)),
              validator: (v) => v != _password.text ? 'รหัสผ่านไม่ตรงกัน' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('สมัครสมาชิก'),
            ),
          ],
        ),
      ),
    );
  }
}
